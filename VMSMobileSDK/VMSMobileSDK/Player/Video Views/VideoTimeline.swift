
import UIKit

protocol Video {
    var startDate: Date { get }
    var state: VideoTimeline.VideoState { get }
    var rangeDurations: [CGFloat] { get }
    var rangeStarts: [CGFloat] { get }
    var cameraStatus: VMSCameraStatusType {get}
    var cameraHighStream: VMSStream? {get}
}

protocol VideoTimelineDelegate: AnyObject {
    func timelineDidScroll(to dateString: String)
    func reloadStripes()
    func hideTimeline()
    func showTimeline()
    func changeTimelabelCenterConstraint(toPoint point: CGFloat)
    func showMarkCreation(on date: Date)
    func updateMarkCreation(withDate date: Date)
    func rewindMark(next: Bool)
    func getUser() -> VMSUser
    func getArchive(mark: VMSEvent)
    func getIsRestrictedArchive() -> Bool
}

final class TimeLabel: UILabel {
    
    public var date: Date?
    public var mark: VMSEvent? {
        didSet {
            if let mark = mark {
                let maxLengthTitle: String = mark.title?.setLenght(to: labelStringLenght()) ?? ""
                self.text = "\(maxLengthTitle)\n\(DateFormatter.yearMonthDay.string(from: mark.from ?? mark.createdAt ?? Date()))"
            }
        }
    }
    public var fixedText: String? {
        didSet {
            self.text = fixedText
        }
    }
    
    func labelStringLenght() -> Int {
        switch UIApplication.shared.statusBarOrientation {
        case .landscapeLeft, .landscapeRight:
            return 70
        default:
            return 35
        }
    }
    
}

class VideoTimeline: UIView {
    
    @IBOutlet weak var videoScrollView: VideoScrollView!
    @IBOutlet weak var stackView: VideoStackView!
    @IBOutlet weak var timeLabel: TimeLabel!
    @IBOutlet weak var datesCollection: DatesCollection!
    @IBOutlet weak var centerView: UIView!
    @IBOutlet weak var prevMarkButton: UIButton!
    @IBOutlet weak var nextMarkButton: UIButton!
    
    // We need those views to prevent pathing trhough gestures when buttons are disabled. Hide them when button are hidden to enlarge space for timeline interaction
    @IBOutlet weak var prevMarkButtonBack:  UIView!
    @IBOutlet weak var nextMarkButtonBack: UIView!
    
    public var currentDate: Date?
    private var datesLayout = UICollectionViewFlowLayout()
    private var pinchRecognizer: UIPinchGestureRecognizer!
    private var allStripesWidth: CGFloat {
        return stackView.allStripesWidth
    }
    private var videos = [Video]()
    fileprivate var zoomFactor: CGFloat = 1
    
    private var currentOrientation = UIDevice.current.orientation
    
    
    // MARK: - PUBLIC
    
    public weak var delegate: VideoTimelineDelegate?
    public var isArchive = Bool()
    public var shouldAskNewArchive: Bool = true
    public var isChangingOrientation: Bool = false
    public var marks: [VMSEvent]?
    public var markLabelVisible: Bool = false
    private var pendingRequestWorkItem: DispatchWorkItem?
    private var allowShowMarks: Bool = true
    private var allowVibration: Bool = false
    
    public enum VideoState: String {
        case active
        case inactive
    }
    
    public func configure(_ videos: [Video], previousTime: Date?, setStartZoom: Bool, allowVibration: Bool) {
        // initial configuration.
        self.videos = videos
        self.allowVibration = allowVibration
        
        centerView.backgroundColor = .playerYellow
        timeLabel.layer.cornerRadius = 8
        timeLabel.clipsToBounds = true
        timeLabel.backgroundColor = UIColor.init(red: 31, green: 33, blue: 40, alpha: 0.75)
        timeLabel.isHidden = true
        
        videoScrollView.delegate = self
        
        pinchRecognizer = UIPinchGestureRecognizer.init(target: self, action: #selector(scalePiece(_:)))
        videoScrollView.addGestureRecognizer(pinchRecognizer)
        
        datesCollection.dataSource = self
        
        datesLayout = datesCollection.collectionViewLayout as! UICollectionViewFlowLayout
        datesCollection.collectionViewLayout = datesLayout
        
        stackView.createStripes(videos: videos, widthOfScreen: UIScreen.main.bounds.width, isReload: false, isRestrictedArchive: delegate?.getIsRestrictedArchive() ?? false)
        datesCollection.startDate = stackView.firstStartDate
        datesCollection.reloadData()
        let longTapCreateMarkRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(timelineLongTap))
        videoScrollView.addGestureRecognizer(longTapCreateMarkRecognizer)
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTapZoom))
        doubleTapRecognizer.numberOfTapsRequired = 2
        videoScrollView.addGestureRecognizer(doubleTapRecognizer)
        
        showMarksButtons(allowShowMarks && delegate?.getUser().hasPermission(.MarksIndex) ?? false)
        
        if setStartZoom {
            setTransform()
        }
        
        if let prevDate = previousTime {
            let nowDate = Date()
            let lastStripeEndDate = Date(timeIntervalSince1970: TimeInterval(stackView.lastStripeEnd))
            let firstStripeStartDate = Date(timeIntervalSince1970: TimeInterval(stackView.firstStripeStart))
            
            if prevDate > nowDate || prevDate > lastStripeEndDate || prevDate < firstStripeStartDate {
                setTenMinBeforeEnd()
            } else {
                shouldAskNewArchive = true
            }
        } else {
            shouldAskNewArchive = true
        }
    }
    
    func setAllowShowMarks(allow: Bool) {
        self.allowShowMarks = allow
    }
    
    @objc func doubleTapZoom() {
        videoScrollView.transform.a >= 5 ? setTransform(transformLevel: 1) : setTransform(transformLevel: 7)
    }
    
    
    func perform(after: TimeInterval, _ block: @escaping () -> ()) {
        // Cancel the currently pending item
        pendingRequestWorkItem?.cancel()
        
        // Wrap our request in a work item
        let requestWorkItem = DispatchWorkItem(block: block)
        
        pendingRequestWorkItem = requestWorkItem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + after, execute:
                                        requestWorkItem)
    }
    
    
    public func setToEnd(needUpdate: Bool = true) {
        hideTimeLabel()
        let end = allStripesWidth - UIScreen.main.bounds.width
        videoScrollView.setContentOffset(CGPoint(x: end, y: 0), animated: false)
        guard let endOffsetDate = contentOffsetToDate(end)  else {return}
        let calendar = Calendar.current
        guard let newEndDate = calendar.date(byAdding: .second, value: -15, to: endOffsetDate) else { return }
        /* если просить архив за дату без минусов, то архив лезет в "будущее", и мы можем получить стрим с камеры, но не с задержкой в 10 секунд, как на лайве, а тот, который только-только записался, поэтому необходимо отнимать некоторое количество секунд.. */
        if needUpdate {
            delegate?.timelineDidScroll(to: DateFormatter.serverUTC.string(from: newEndDate))
        }
    }
    
    public func setToBeginning() {
        hideTimeLabel()
        videoScrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        guard let beginningOffsetDate = contentOffsetToDate(0) else {return}
        delegate?.timelineDidScroll(to: DateFormatter.serverUTC.string(from: beginningOffsetDate))
    }
    
    public func setTenMinBeforeEnd() {
        let date = Date(timeIntervalSince1970: TimeInterval(stackView.lastStripeEnd))
        
        let calendar = Calendar.current
        guard let newDate = calendar.date(byAdding: .minute, value: -10, to: date) else { return }
        
        videoScrollView.setContentOffset(CGPoint(x: dateToContentOffset(newDate), y: 0), animated: false)
        delegate?.timelineDidScroll(to: DateFormatter.serverUTC.string(from: newDate))
        datesCollection.reloadData()
    }
    
    public func isEnd() -> Bool {
        return Int(videoScrollView.contentOffset.x) >= Int(allStripesWidth - UIScreen.main.bounds.width)
    }
    
    public func setDate(_ date: Date, _ animated: Bool) {
        let offset = CGPoint(x: dateToContentOffset(date), y: videoScrollView.contentOffset.y)
        self.videoScrollView.setContentOffset(offset, animated: animated)
        
    }
    
    public func reloadArchiveStripes() {
        setTransform()
    }
    
    public func getStartScreenDate() -> Date? {
        return contentOffsetToDate(videoScrollView.contentOffset.x - UIScreen.main.bounds.width / 2)
    }
    
    public func getEndScreendate() -> Date? {
        return contentOffsetToDate(videoScrollView.contentOffset.x + UIScreen.main.bounds.width / 2)
    }
    
    public func getCurrentTimelineDate() -> Date? {
        return contentOffsetToDate(videoScrollView.contentOffset.x)
    }
    
    
    // MARK: - PRIVATE
    
    private func dateToContentOffset(_ current: Date) -> CGFloat {
        var currentDate = current
        var start = Date.init(timeIntervalSince1970: (TimeInterval(videos.first?.rangeStarts.first ?? CGFloat(Date().timeIntervalSince1970))))
        if stackView.tooManyDurations {
            let firstStart =  TimeInterval(stackView.firstStripeStart)
            start = Date.init(timeIntervalSince1970: firstStart)
        }
        let end = Date(timeIntervalSince1970: TimeInterval(stackView.lastStripeEnd))
        
        if current < start {
            return 0
        } else if current > end {
            currentDate = end
        }
        
        let seconds = currentDate.timeIntervalSince(start)
        
        let offset = CGFloat(seconds) * stackView.koeficcient
        
        return offset
    }
    
    private func contentOffsetToDate(_ offset: CGFloat) -> Date? {
        
        var start = Date.init(timeIntervalSince1970: (TimeInterval(videos.first?.rangeStarts.first ?? CGFloat(Date().timeIntervalSince1970))))
        if stackView.tooManyDurations {
            let firstStart =  TimeInterval(stackView.firstStripeStart)
            start = Date.init(timeIntervalSince1970: firstStart)
        }
        let seconds = Int(offset / stackView.koeficcient)
        let calendar = Calendar.current
        let newDate = calendar.date(byAdding: .second, value: seconds, to: start)
        return newDate
    }
    
    public func setTransform(transformLevel: Int = 7) {
        
        if datesCollection.transform.a >= 1 {
            
            datesCollection.transform = .identity
            pinchRecognizer.view?.transform = .identity
            datesCollection.transform = ((pinchRecognizer.view?.transform.scaledBy(x: CGFloat(transformLevel), y: 1))!)
            pinchRecognizer.view?.transform = (pinchRecognizer.view?.transform.scaledBy(x: CGFloat(transformLevel), y: 1))!
            adjustZoomLevel(transformLevel, pinchRecognizer)
            stackView.createStripes(videos: videos, widthOfScreen: UIScreen.main.bounds.width, isReload: false, isRestrictedArchive: delegate?.getIsRestrictedArchive() ?? false)
            datesCollection.screenDurationChanged(stackView.screenDuration)
            
            // При первом заходе на камеру, переворачивании её в лэндскейп и уходе в архив коллекция почему-то ведёт себя странно и не обновляется, перенесла это в метод updateDatesCollection, чтобы UI точно успел обновиться
            perform(#selector(updateDatesCollection), with: nil, afterDelay: 0.1)
            
            if let marks = marks, allowShowMarks {
                configureMarks(marks)
            }
        }
    }
    
    @objc func updateDatesCollection() {
        datesCollection.layoutSubviews()
    }
    
    // MARK: - Rotation of screen
    
    public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.isChangingOrientation = true
        currentDate = contentOffsetToDate(videoScrollView.contentOffset.x)
    }
    
    public func orientationChanged() {
        self.isChangingOrientation = false
        let orientation = UIDevice.current.orientation
        if orientation == .faceUp || orientation == .faceDown {
            return
        }
        
        if videos.count >= 1 {
            stackView.createStripes(videos: videos, widthOfScreen: UIScreen.main.bounds.width, isReload: false, isRestrictedArchive: delegate?.getIsRestrictedArchive() ?? false)
            datesCollection.reloadData()
        }
        if let date = currentDate {
            setDate(date, true)
            datesCollection.reloadData()
        }
        guard let marks = marks else {return}
        configureMarks(marks)
        self.markLabelVisible = false
        self.hideTimeLabel()
        
    }
    
    //MARK: - Zoom
    
    private func setMinimumLineSpacing(_ spacing: CGFloat) {
        if datesLayout.minimumLineSpacing != spacing {
            datesLayout.minimumLineSpacing = spacing
        }
    }
    
    public func setDefaultZoom() {
        adjustZoomLevel(7, pinchRecognizer)
    }
    
    private func adjustZoomLevel(_ zoomedScale: Int,_ gestureRecognizer : UIPinchGestureRecognizer) {
        
        switch zoomedScale {
        case 1:
            datesCollection.hideHalfCells = true
            zoomFactor = 1
            stackView.screenDuration = 604800 // week
            setMinimumLineSpacing(0)
            
        case 2:
            datesCollection.hideHalfCells = true
            zoomFactor = 1
            stackView.screenDuration = 604800 // halfweek
            setMinimumLineSpacing(0)
            
        case 3:
            datesCollection.hideHalfCells = false
            zoomFactor = 1
            stackView.screenDuration = 453600 // 42 hours
            setMinimumLineSpacing(0)
            
        case 4:
            datesCollection.hideHalfCells = false
            zoomFactor = 1
            stackView.screenDuration = 345600 // 24 hours
            setMinimumLineSpacing(0)
            
        case 5:
            datesCollection.hideHalfCells = false
            zoomFactor = 1
            stackView.screenDuration = 216000 // 12 hours
            setMinimumLineSpacing(0)
            
        case 6:
            datesCollection.hideHalfCells = false
            zoomFactor = 1
            stackView.screenDuration = 86400// 4 hours
            setMinimumLineSpacing(0)
            
        case 7:
            datesCollection.hideHalfCells = false
            zoomFactor = 1
            stackView.screenDuration = 25200 // hour
            setMinimumLineSpacing(-12.5)
            
            
        case 8:
            datesCollection.hideHalfCells = false
            zoomFactor = 1
            stackView.screenDuration = 14400 // 30 min
            setMinimumLineSpacing(-12.5)
            
        case 9:
            datesCollection.hideHalfCells = false
            zoomFactor = 1
            stackView.screenDuration = 5400 // 10 min
            setMinimumLineSpacing(-15)
            
            
        case 10:  /* из-за того, что увеличено в 10 раз, то 604800/64/10 == 945 сек == 15.75 минут => 10 минут будет просто 600 * 10 = 6000 */
            zoomFactor = 1
            stackView.screenDuration = 6000
            setMinimumLineSpacing(-15)
        default:
            zoomFactor = 1
            stackView.screenDuration = 6000
        }
        datesCollection.transform = ((gestureRecognizer.view?.transform.scaledBy(x: gestureRecognizer.scale, y: 1))!)
        
        for subview in videoScrollView.subviews {
            if subview is MarkView {
                subview.transform = (gestureRecognizer.view?.transform.scaledBy(x: gestureRecognizer.scale, y: 1))!
            }
        }
        gestureRecognizer.view?.transform = (gestureRecognizer.view?.transform.scaledBy(x: gestureRecognizer.scale, y: 1))!
    }
    
    @objc private func scalePiece(_ gestureRecognizer : UIPinchGestureRecognizer) {
        guard gestureRecognizer.view != nil else { return }
        
        let minWidth = UIScreen.main.bounds.width
        let maxWidth = UIScreen.main.bounds.width * 10
        
        let newWidth = gestureRecognizer.scale * videoScrollView.frame.width
        let zoomedScale = newWidth / minWidth
        
        guard  let currentScrollDate = contentOffsetToDate(videoScrollView.contentOffset.x) else {return}
        
        
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            if (newWidth >= minWidth && newWidth <= maxWidth) {
                adjustZoomLevel(Int(zoomedScale), gestureRecognizer)
                datesCollection.screenDurationChanged(stackView.screenDuration)
                stackView.createStripes(videos: videos, widthOfScreen: UIScreen.main.bounds.width, isReload: true, isRestrictedArchive: delegate?.getIsRestrictedArchive() ?? false)
                if let marks = marks, allowShowMarks {
                    self.configureMarks(marks)
                }
                datesCollection.reloadData()
                setDate(currentScrollDate, false)
            }
        } else if gestureRecognizer.state == .ended {
            stackView.createStripes(videos: videos, widthOfScreen: UIScreen.main.bounds.width, isReload: true, isRestrictedArchive: delegate?.getIsRestrictedArchive() ?? false)
            if let marks = marks, allowShowMarks {
                self.configureMarks(marks)
            }
            datesCollection.layoutIfNeeded()
            datesCollection.reloadData()
            setDate(currentScrollDate, false)
        }
        gestureRecognizer.scale = 1.0
    }
    
    @IBAction func previousMarkAction(_ sender: Any?) {
        delegate?.rewindMark(next: false)
    }
    
    @IBAction func nextMarkAction(_ sender: Any?) {
        delegate?.rewindMark(next: true)
    }
}
// MARK:- Marks Extension

extension VideoTimeline {
    
    @objc private func timelineLongTap(recognizer: UILongPressGestureRecognizer) {
        if let user = delegate?.getUser(), user.hasPermission(.MarksStore), user.hasPermission(.MarksIndex) {
            if recognizer.state == .began {
                let location = recognizer.location(in: self.videoScrollView)
                let date = contentOffsetToDate(location.x - UIScreen.main.bounds.width / 2)
                let lastDate =  Date(timeIntervalSince1970: TimeInterval(stackView.lastStripeEnd))
                if let date = date, date >= stackView.firstStartDate, date <= lastDate {
                    UIDevice.vibrate(isAllowed: self.allowVibration)
                    delegate?.showMarkCreation(on: date)
                    recognizer.state = .ended
                }
            }
        }
    }
    
    private func removeMarksView() {
        videoScrollView.subviews.forEach { (view) in
            if view is MarkView {
                view.removeFromSuperview()
                
                NSLayoutConstraint.deactivate(view.constraints)
            }
        }
    }
    
    public func removeMarks(hideTamelabel: Bool = true) {
        removeMarksView()
        self.marks?.removeAll()
        if hideTamelabel {
            self.hideTimeLabel()
            self.timeLabel.text = ""
        }
        showMarksButtons(false)
    }
    
    public func configureMarks(_ marks: [VMSEvent], hideTimelabel: Bool = true) {
        removeMarks(hideTamelabel: hideTimelabel)
        drawMarks(marks: marks, koefficent: stackView.koeficcient)
        showMarksButtons(true)
    }
    
    private func drawMarks(marks: [VMSEvent], koefficent: CGFloat) {
        self.marks = marks
        for index in 0..<marks.count {
            
            guard let start = marks[index].from else { return }
            let startFloat = CGFloat(start.timeIntervalSince1970)
            
            let startPoint = TimeInterval(startFloat)
            let startDate = Date(timeIntervalSince1970: startPoint)
            let startOffset = dateToContentOffset(startDate) + stackView.firstEmptyStripeEnd
            let markStripe = MarkView()
            markStripe.backgroundColor = .clear
            videoScrollView.addSubview(markStripe)
            let scale = datesCollection.transform.a
            markStripe.scale = scale
            markStripe.translatesAutoresizingMaskIntoConstraints = false
            markStripe.widthAnchor.constraint(equalToConstant: 33 / scale).isActive = true
            markStripe.centerXAnchor.constraint(equalTo: videoScrollView.leadingAnchor, constant: startOffset).isActive = true
            markStripe.heightAnchor.constraint(equalToConstant: 33).isActive = true
            markStripe.topAnchor.constraint(equalTo: videoScrollView.topAnchor, constant: 5).isActive = true
            markStripe.configure(mark: marks[index])
            markStripe.layoutIfNeeded()
            self.videoScrollView.layoutIfNeeded()
            
            markStripe.tapHandler = { [weak self] mark in
                guard let self = self else {return}
                guard let m = mark else {return}
                self.setDate(start, true)
                self.delegate?.getArchive(mark: m)
                self.delegate?.changeTimelabelCenterConstraint(toPoint: 0)
                self.timeLabel.isHidden = false
                self.markLabelVisible = true
                self.timeLabel.mark = m
                self.showMarksButtons(true)
                self.performHideMark()
            }
            
            markStripe.longTapHandler = { [weak self] (mark, globalPoint) in
                guard let self = self else {return}
                guard let m = mark, let globalPoint = globalPoint else {return}
                
                self.delegate?.changeTimelabelCenterConstraint(toPoint: globalPoint.x)
                self.timeLabel.isHidden = false
                self.timeLabel.mark = m
                self.showMarksButtons(true)
                self.markLabelVisible = true
                self.performHideMark()
            }
        }
    }
    
    public func performHideMark() {
        self.perform(after: 4) { [weak self] in
            guard let self else { return }
            if self.markLabelVisible {
                self.hideTimeLabel()
                self.markLabelVisible = false
                self.timeLabel.mark = nil
            }
        }
    }
    
    func showLongPin() {
        self.centerView.isHidden = true
        let longPinImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 44, height: 85))
        longPinImageView.image = UIImage(named: "selected_pin", in: Bundle(for: VMSPlayerController.self), with: nil)?.imageWithColor()
        longPinImageView.backgroundColor = .clear
        self.insertSubview(longPinImageView, belowSubview: timeLabel)
        longPinImageView.translatesAutoresizingMaskIntoConstraints = false
        longPinImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 0).isActive = true
        longPinImageView.bottomAnchor.constraint(equalTo: videoScrollView.bottomAnchor, constant: 0).isActive = true
        longPinImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        longPinImageView.heightAnchor.constraint(equalToConstant: 85).isActive = true
        self.layoutIfNeeded()
    }
    
    func deleteLongPin() {
        for subview in self.subviews {
            if subview is UIImageView {
                subview.removeFromSuperview()
            }
        }
        self.centerView.isHidden = false
    }
    
    func showMarksButtons(_ show: Bool) {
        nextMarkButton.isHidden = !show
        prevMarkButton.isHidden = !show
        nextMarkButtonBack.isHidden = !show
        prevMarkButtonBack.isHidden = !show
    }
    
    private func hideTimeLabel() {
        timeLabel.isHidden = true
        //        showMarksButtons(false)
    }
    
    public func showTimeLabel(message: String) {
        timeLabel.fixedText = message
        timeLabel.isHidden = false
        self.perform(after: 4) { [weak self] in
            self?.timeLabel.fixedText = nil
            self?.hideTimeLabel()
        }
    }
    
    
}

// MARK: - Scroll Delegate

extension VideoTimeline: UIScrollViewDelegate {
    
    
    func seekForNextAvailableTime() {
        guard let currentDate = contentOffsetToDate(videoScrollView.contentOffset.x) else {
            return
        }
        if stackView.endBeforeEmptyDuration.count >= 1 {
            for index in 0...stackView.endBeforeEmptyDuration.count - 1 {
                if currentDate >= stackView.endBeforeEmptyDuration[index] && currentDate < stackView.startAfterEmptyDuration[index] {
                    let afterOffset = dateToContentOffset(stackView.startAfterEmptyDuration[index])
                    guard let newDate = contentOffsetToDate(afterOffset) else {return}
                    setDate(newDate, true)
                    delegate?.timelineDidScroll(to: DateFormatter.serverUTC.string(from: newDate))
                }
            }
        }
    }
    
    // Only for RTSP bacause we get date from stream URL
    func currentDateIsOutOfRange(date: Date) -> Bool {
        if stackView.endBeforeEmptyDuration.count >= 1 {
            for index in 0...stackView.endBeforeEmptyDuration.count - 1 {
                if date >= stackView.endBeforeEmptyDuration[index] &&
                    date <= stackView.startAfterEmptyDuration[index] - TimeInterval(15) {
                    return true
                }
            }
        }
        return false
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        datesCollection.didScroll(scrollView.contentOffset.x)
        guard let currentDate = contentOffsetToDate(scrollView.contentOffset.x) else {
            return
        }
        
        if !videoScrollView.isUserDragging && !videoScrollView.isDecelerating && !videoScrollView.isAnimatingScroll && !isChangingOrientation { // перескакивание неактивных участков
            seekForNextAvailableTime()
        }
        if !videoScrollView.isDecelerating {
            UIDevice.selectionVibrate(isAllowed: self.allowVibration)
        }
        
        if !self.markLabelVisible && timeLabel.fixedText == nil {
            delegate?.changeTimelabelCenterConstraint(toPoint: 0)
            timeLabel.date = currentDate
            timeLabel.text = DateFormatter.yearMonthDay.string(from: currentDate)
            delegate?.updateMarkCreation(withDate: currentDate)
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        timeLabel.isHidden = false
        videoScrollView.isUserDragging = true
        self.timeLabel.fixedText = nil
        self.markLabelVisible = false
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        hideTimeLabel()
        videoScrollView.isUserDragging = false
        if isArchive, !decelerate, !videoScrollView.isDecelerating {
            if let date = timeLabel.date {
                delegate?.timelineDidScroll(to: DateFormatter.serverUTC.string(from: date))
            }
        }
    }
    
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        videoScrollView.isAnimatingScroll = false
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        hideTimeLabel()
        if self.isArchive && !isEnd() {
            if let date = timeLabel.date {
                delegate?.timelineDidScroll(to: DateFormatter.serverUTC.string(from: date))
            }
        }
    }
}


extension VideoTimeline: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case datesCollection:
            let numberOfItems = allStripesWidth / 10
            return Int(numberOfItems)
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch  collectionView {
        case datesCollection:
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "dateCell", for: indexPath) as? DateCollectionCell else {return UICollectionViewCell()}
            let cellFrameOrgin = cell.center.x - UIScreen.main.bounds.width / 2
            
            if indexPath.row % 2 == 0, datesCollection.hideHalfCells {
                cell.configure(offset: cellFrameOrgin, startDate: datesCollection.startDate, koeficcient: stackView.koeficcient, screenDuration: datesCollection.screenDurationForCell)
                cell.configureHiddenCells()
            } else {
                cell.configure(offset: cellFrameOrgin, startDate: datesCollection.startDate, koeficcient: stackView.koeficcient, screenDuration: datesCollection.screenDurationForCell)
            }
            
            cell.transform = ((pinchRecognizer.view?.transform.scaledBy(x: pinchRecognizer.scale / zoomFactor, y: 1))!)
            
            return cell
            
        default:
            return UICollectionViewCell()
        }
        
    }
}

// MARK: - StackView

class VideoStackView: UIStackView {
    
    private var screenWidth = UIScreen.main.bounds.width
    
    fileprivate var allStripesWidth = CGFloat()
    fileprivate var stripesWidths = [CGFloat]()
    fileprivate var tooManyDurations = false
    
    public var durations = [DurationFloat]()
    public var endBeforeEmptyDuration = [Date]()
    public var startAfterEmptyDuration = [Date]()
    public var firstStartDate = Date()
    
    public var lastStripeEnd = CGFloat()
    
    let stripeHeight: CGFloat = 6
    
    
    // MARK: - Calculations
    
    fileprivate let defaultScreenDuration: CGFloat = 604800 // 24 hours
    
    public var screenDuration: CGFloat = 3600
    // стандартное значение для первого запуска
    
    
    fileprivate var firstStripeStart = CGFloat()
    
    fileprivate var firstEmptyStripeEnd = CGFloat()
    
    public var koeficcient: CGFloat {
        return UIScreen.main.bounds.width / screenDuration
    }
    
    public func createStripes(videos: [Video], widthOfScreen: CGFloat?, isReload: Bool, isRestrictedArchive: Bool) {
        cleanStackContent()
        
        if !isReload {
            durations.removeAll()
            endBeforeEmptyDuration.removeAll()
            startAfterEmptyDuration.removeAll()
            createDurations(videos: videos, isRestrictedArchive: isRestrictedArchive)
        }
        
        let firstStipe = createEmptyStripe(width: (widthOfScreen ?? screenWidth) / 2)
        self.addArrangedSubview(firstStipe)
        
        drawStripes(durations: durations, koefficent: koeficcient)
        
        let endStipe = createEmptyStripe(width: (widthOfScreen ?? screenWidth) / 2)
        self.addArrangedSubview(endStipe)
        
    }
    
    private func createDurations(videos: [Video], isRestrictedArchive: Bool) {
        
        var videoDurations = videos.flatMap {$0.rangeDurations}
        
        var videoStarts = videos.flatMap( {$0.rangeStarts})
        
        /* MD-896 bug_The archive stream should be available by the complete period of archive_storage_days
        if videoDurations.count >= 300 {
            let startIndex = videoDurations.count - 95
            tooManyDurations = true
            videoDurations.removeFirst(startIndex)
            videoStarts.removeFirst(startIndex)
        }*/
        
        if videoStarts.count >= 1 {
            firstStripeStart = videoStarts[0]
            let startDate = Date(timeIntervalSince1970: TimeInterval(firstStripeStart))
            firstStartDate = startDate
        }
        
        let currentTime = CGFloat(Date().timeIntervalSince1970)
        
        for (index, durationVal) in videoDurations.enumerated() {
        
            let activeDuration = DurationFloat(duration: durationVal)
            
            if index >= 1 { // полоска между двумя рейнджами -- неактивное время.
                let previousDuration = videoDurations[index-1] + videoStarts[index-1]
                let emptyDuration = DurationFloat(duration: videoStarts[index] - previousDuration, state: false)
                durations.append(emptyDuration)
                endBeforeEmptyDuration.append(Date(timeIntervalSince1970: TimeInterval(previousDuration)))
                startAfterEmptyDuration.append(Date(timeIntervalSince1970: TimeInterval(videoStarts[index])))
            }
            
            if index == videoDurations.count - 1 { // дотягиваем последнюю полоску до текущего времени, ибо время на беке обновляется раз в 10? минут
                let lastDurationEndpoint = durationVal + videoStarts[index]
                let neededSeconds = DurationFloat(duration: currentTime - lastDurationEndpoint)
                let durationWithLastSeconds = DurationFloat(duration: activeDuration.duration + neededSeconds.duration)
                
                /*
                 Это была проверка на то, обновился ли сервер или архива действительно нет. Однако пока что сказали убрать и в любом случае, если камера активна, дорисовывать до конца.
                 
                 if neededSeconds >= 1200 {
                 durationWithLastSeconds = duration
                 }
                 */
                
                if videos.count == 1 {
                    switch videos[0].cameraHighStream?.status {
                    case .active:
                        // если доступ к архиву ограничен, то показываем только доступные рейнжи, не дотягиваем до конца
                        if isRestrictedArchive {
                            durations.append(activeDuration)
                            lastStripeEnd = videoStarts[index] + activeDuration.duration
                        } else {
                            durations.append(durationWithLastSeconds)
                            lastStripeEnd = videoStarts[index] + durationWithLastSeconds.duration
                        }
                    case .inactive, .some(.NULL), .none:
                        durations.append(activeDuration)
                        lastStripeEnd = videoStarts[index] + activeDuration.duration
                    }
                }
            } else {
                durations.append(activeDuration)
            }
        }
    }
    
    private func drawStripes(durations: [DurationFloat], koefficent: CGFloat) {
        
        if durations.count >= 1 {
            for (index, durationVal) in durations.enumerated() {
                let durationWithKoef = durationVal.duration * koeficcient
                let stripe = UIView(frame: CGRect(x: 0, y: 0, width: durationWithKoef, height: stripeHeight))
                stripe.backgroundColor = durationVal.activeState == true ? stripeColor(.active) : stripeColor(.inactive)
                if index == durations.count - 1 {
                    stripe.backgroundColor = stripeColor(.active)
                }
                stripe.widthAnchor.constraint(equalToConstant: durationWithKoef).isActive = true
                self.addArrangedSubview(stripe)
                let stripeWidth = stripe.frame.width
                allStripesWidth += stripeWidth
                stripesWidths.append(stripeWidth)
            }
        }
    }
    
    private func cleanStackContent() {
        removeAllArrangedSubviews()
        allStripesWidth = 0
        stripesWidths.removeAll()
    }
    
    private func createEmptyStripe(width: CGFloat) -> UIView {
        let firstStripe = UIView(frame: CGRect(x: 0, y: 0, width: width, height: stripeHeight))
        firstStripe.backgroundColor = .clear
        firstStripe.widthAnchor.constraint(equalToConstant: width).isActive = true
        
        let widthOfStripe = firstStripe.frame.width
        self.firstEmptyStripeEnd = widthOfStripe
        allStripesWidth += widthOfStripe
        stripesWidths.append(widthOfStripe)
        return firstStripe
    }
    
    private func stripeColor(_ videoState: VideoTimeline.VideoState) -> UIColor {
        switch videoState {
        case .active:
            return .init(red: 2, green: 174, blue: 158, alpha: 0.75)
        case .inactive:
            return UIColor.init(hex: 0x4D4D4D)
        }
    }
}

class DurationFloat {
    
    let duration: CGFloat
    let activeState: Bool
    
    init(duration: CGFloat, state: Bool) {
        self.duration = duration
        self.activeState = state
    }
    
    init(duration: CGFloat) {
        self.duration = duration
        self.activeState = true
    }
    
}

class MarkView: UIView {
    
    public var tapHandler: ((VMSEvent?) -> Void)?
    public var longTapHandler: ((VMSEvent?, CGPoint?) -> Void)?
    private var mark: VMSEvent?
    public var scale: CGFloat?
    
    override func removeFromSuperview() {
        self.mark = nil
        self.tapHandler = nil
        self.longTapHandler = nil
        self.scale = nil
        super.removeFromSuperview()
    }
    
    override func draw(_ rect: CGRect) {
        
        guard let context = UIGraphicsGetCurrentContext() else {return}
        
        var tempScale: CGFloat = 10.0
        if let scale = scale {
            tempScale = scale
        }
        
        self.contentScaleFactor = tempScale * 4
        //// Color Declarations
        //        let fillColor = UIColor(red: 0.184, green: 0.404, blue: 0.992, alpha: 1.000)
        let fillColor = mark?.type == VMSEventType.defaultType ? UIColor.main : UIColor.markDetect
        
        //// Group
        context.saveGState()
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        
        //// Clip Rectangle
        let rectanglePath = UIBezierPath(rect: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
        rectanglePath.addClip()
        
        
        //// Group 2
        //// Bezier Drawing
        let bezierPath = UIBezierPath()
        if let scale = scale {
            bezierPath.move(to: CGPoint(x: 22.95 / scale, y: 22.2))
            bezierPath.addLine(to: CGPoint(x: 15 / scale, y: 30.16))
            bezierPath.addLine(to: CGPoint(x: 7.05 / scale, y: 22.2))
            bezierPath.addCurve(to: CGPoint(x: 3.97 / scale, y: 16.44), controlPoint1: CGPoint(x: 5.47 / scale, y: 20.63), controlPoint2: CGPoint(x: 4.4 / scale, y: 18.63))
            bezierPath.addCurve(to: CGPoint(x: 4.61 / scale, y: 9.94), controlPoint1: CGPoint(x: 3.53 / scale, y: 14.26), controlPoint2: CGPoint(x: 3.75 / scale, y: 12))
            bezierPath.addCurve(to: CGPoint(x: 8.75 / scale, y: 4.9), controlPoint1: CGPoint(x: 5.46 / scale, y: 7.89), controlPoint2: CGPoint(x: 6.9 / scale, y: 6.13))
            bezierPath.addCurve(to: CGPoint(x: 15 / scale, y: 3), controlPoint1: CGPoint(x: 10.6 / scale, y: 3.66), controlPoint2: CGPoint(x: 12.77 / scale, y: 3))
            bezierPath.addCurve(to: CGPoint(x: 21.25 / scale, y: 4.9), controlPoint1: CGPoint(x: 17.23 / scale, y: 3), controlPoint2: CGPoint(x: 19.4 / scale, y: 3.66))
            bezierPath.addCurve(to: CGPoint(x: 25.39 / scale, y: 9.94), controlPoint1: CGPoint(x: 23.1 / scale, y: 6.13), controlPoint2: CGPoint(x: 24.54 / scale, y: 7.89))
            bezierPath.addCurve(to: CGPoint(x: 26.03 / scale, y: 16.44), controlPoint1: CGPoint(x: 26.25 / scale, y: 12), controlPoint2: CGPoint(x: 26.47 / scale, y: 14.26))
            bezierPath.addCurve(to: CGPoint(x: 22.95 / scale, y: 22.2), controlPoint1: CGPoint(x: 25.6 / scale, y: 18.63), controlPoint2: CGPoint(x: 24.53 / scale, y: 20.63))
            bezierPath.close()
            bezierPath.move(to: CGPoint(x: 15 / scale, y: 16.75))
            bezierPath.addCurve(to: CGPoint(x: 16.77 / scale, y: 16.02), controlPoint1: CGPoint(x: 15.66 / scale, y: 16.75), controlPoint2: CGPoint(x: 16.3 / scale, y: 16.49))
            bezierPath.addCurve(to: CGPoint(x: 17.5 / scale, y: 14.25), controlPoint1: CGPoint(x: 17.24 / scale, y: 15.55), controlPoint2: CGPoint(x: 17.5 / scale, y: 14.91))
            bezierPath.addCurve(to: CGPoint(x: 16.77 / scale, y: 12.48), controlPoint1: CGPoint(x: 17.5 / scale, y: 13.59), controlPoint2: CGPoint(x: 17.24 / scale, y: 12.95))
            bezierPath.addCurve(to: CGPoint(x: 15 / scale, y: 11.75), controlPoint1: CGPoint(x: 16.3 / scale, y: 12.01), controlPoint2: CGPoint(x: 15.66 / scale, y: 11.75))
            bezierPath.addCurve(to: CGPoint(x: 13.23 / scale, y: 12.48), controlPoint1: CGPoint(x: 14.34 / scale, y: 11.75), controlPoint2: CGPoint(x: 13.7 / scale, y: 12.01))
            bezierPath.addCurve(to: CGPoint(x: 12.5 / scale, y: 14.25), controlPoint1: CGPoint(x: 12.76 / scale, y: 12.95), controlPoint2: CGPoint(x: 12.5 / scale, y: 13.59))
            bezierPath.addCurve(to: CGPoint(x: 13.23 / scale, y: 16.02), controlPoint1: CGPoint(x: 12.5 / scale, y: 14.91), controlPoint2: CGPoint(x: 12.76 / scale, y: 15.55))
            bezierPath.addCurve(to: CGPoint(x: 15 / scale, y: 16.75), controlPoint1: CGPoint(x: 13.7 / scale, y: 16.49), controlPoint2: CGPoint(x: 14.34 / scale, y: 16.75))
            bezierPath.close()
            fillColor.setFill()
            bezierPath.fill()
            
            context.endTransparencyLayer()
            context.restoreGState()
        }
    }
    
    func configure(mark: VMSEvent) {
        
        var tempScale: CGFloat = 10.0
        if let scale = scale {
            tempScale = scale
        }
        self.layer.contentsScale = tempScale * 4 // убирает пикселизацию при зуме.
        
        self.mark = mark
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.addGestureRecognizer(tapRecognizer)
        let longTapRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longTap))
        self.addGestureRecognizer(longTapRecognizer)
    }
    
    @objc func tapped() {
        tapHandler?(mark)
    }
    
    @objc func longTap() {
        let globalPoint = self.superview?.convert(self.center, to: nil)
        longTapHandler?(mark, globalPoint)
    }
}


// MARK: - Main Scroll View of the Timeline

class VideoScrollView: UIScrollView {
    
    fileprivate var isUserDragging: Bool = false
    fileprivate var isAnimatingScroll: Bool = false
    
    public func centerOffset(halfWidthOfScroll: CGFloat) {
        let frame = self.frame.width / 2
        self.contentOffset.x = halfWidthOfScroll - frame
    }
    
    override func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        super.setContentOffset(contentOffset, animated: animated)
        if animated {
            isAnimatingScroll = true
        } else {
            isAnimatingScroll = false
        }
    }
    
    override var transform: CGAffineTransform { // Zooming
        set {
            var constrainedTransform = CGAffineTransform.identity
            //            constrainedTransform.d = self.startScale * newValue.d // vertical zoom
            constrainedTransform.a = newValue.a // horizontal zoom
            super.transform = constrainedTransform
        }
        get {
            return super.transform
        }
    }
}


class DatesCollection: UICollectionView {
    
    
    var hideHalfCells = true
    var screenDurationForCell: CGFloat = 3600 // 3600
    var startDate = Date()
    
    func newStartDate(_ date: Date) {
        self.startDate = date
    }
    
    func screenDurationChanged(_ screenDuration: CGFloat) {
        self.screenDurationForCell = screenDuration
    }
    
    func didScroll(_ offset: CGFloat) {
        self.contentOffset.x = offset
    }
    
}

class DateCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var indicator: UIView!
    
    /**
     HH:mm:ss
     */
    private lazy var hourMinuteSecond: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        return dateFormatter
    }()
    
    /**
     HH:mm
     */
    private lazy var hourMinute: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter
    }()
    
    /**
     dd.MM
     */
    private lazy var monthDayNoHour: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM"
        return dateFormatter
    }()
    
    func configure(offset: CGFloat, startDate: Date, koeficcient: CGFloat, screenDuration: CGFloat) {
        
        let seconds = Int(offset / koeficcient)
        let calendar = Calendar.current
        guard let newDate = calendar.date(byAdding: .second, value: seconds, to: startDate) else {return}
        
        switch screenDuration {
        case 600...1200:
            dateLabel.text = hourMinuteSecond.string(from: newDate)
        case 1200...1800:
            dateLabel.text = hourMinute.string(from: newDate)
        case 1800...3600: // 30 min - 1 hour
            dateLabel.text = hourMinute.string(from: newDate)
        case 3600...82800: // 1 - 23 hours
            dateLabel.text = hourMinute.string(from: newDate)
        case 82800...86400: // 23 - 24 hours
            dateLabel.text = hourMinute.string(from: newDate)
        case 86400...345600:
            dateLabel.text = hourMinute.string(from: newDate)
        case 345600...604800:
            dateLabel.text = monthDayNoHour.string(from: newDate)
        default:
            dateLabel.text = hourMinute.string(from: newDate)
        }
        self.dateLabel.textColor = .white
        self.indicator.backgroundColor = .white
        self.transform = .identity
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.dateLabel.textColor = .clear
        indicator.backgroundColor = .clear
        self.transform = .identity
    }
    
    func configureHiddenCells() {
        self.dateLabel.textColor = .clear
        indicator.backgroundColor = .clear
    }
    
    override var transform: CGAffineTransform { // Prevent indicator zoom
        set {
            var constrainedTransform = CGAffineTransform.identity
            constrainedTransform.a /= newValue.a
            super.transform = constrainedTransform
        }
        get {
            return super.transform
        }
    }
}

