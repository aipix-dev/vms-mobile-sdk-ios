
import UIKit
import AVFoundation

public class VMSPlayerController: UIViewController {
    
    @IBOutlet weak var videoLayerScroll: UIScrollView!
    @IBOutlet weak var videoLayer: VideoLayerView!
    @IBOutlet weak var topView: VideoHeaderView!
    @IBOutlet weak var bottomView: VideoFooterView!
    @IBOutlet weak var timeline: VideoTimeline!
    @IBOutlet weak var archivePickerView: UIView!
    @IBOutlet weak var timePicker: UIPickerView!
    @IBOutlet weak var archiveDatePicker: UIDatePicker!
    @IBOutlet weak var archivePickerBottom: NSLayoutConstraint!
    @IBOutlet weak var archiveBackgroundView: UIView!
    @IBOutlet weak var archiveCancelButton: UIButton! {
        didSet {
            archiveCancelButton.setTitleColor(.playerYellow, for: .normal)
        }
    }
    @IBOutlet weak var archiveDoneButton: UIButton!
    @IBOutlet weak var gravityButton: UIButton!
    @IBOutlet weak var screenshotButton: UIButton! {
        didSet {
            screenshotButton.layer.cornerRadius = screenshotButton.bounds.height / 2
        }
    }
    @IBOutlet weak var soundButton: UIButton! {
        didSet {
            soundButton.layer.cornerRadius = soundButton.bounds.height / 2
        }
    }
    
    @IBOutlet weak var ptzView: PTZView! {
        didSet {
            ptzView.layer.cornerRadius = 20
        }
    }
    
    @IBOutlet weak var ptzButton: UIButton! {
        didSet {
            ptzButton.layer.cornerRadius = ptzButton.bounds.height / 2 
        }
    }
    @IBOutlet weak var liveOptionsButton: UIButton! {
        didSet {
            liveOptionsButton.layer.cornerRadius = liveOptionsButton.bounds.height / 2
        }
    }
    
    @IBOutlet weak var soundBottomButton: UIButton! 
    @IBOutlet weak var optionsButton: UIButton!
    
    @IBOutlet weak var optionsView: UIView!
    @IBOutlet weak var timeLabelCenterXConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var noDataView: PlayerNoDataView!
    
    @IBOutlet weak var createMarkContainer: UIView!
    private weak var markCreationController: CreateMarkController?
    
    @IBOutlet weak var playerScrollBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var createMarkBottomVerticalConstraint: NSLayoutConstraint!
    @IBOutlet weak var createMarkTrailingHorizontal: NSLayoutConstraint!
    @IBOutlet weak var createMarkTopHorizontal: NSLayoutConstraint!
    @IBOutlet weak var createMarkWidthHorizontal: NSLayoutConstraint!
    @IBOutlet weak var createMarkLeadingHorizontal: NSLayoutConstraint!
    @IBOutlet weak var createMarkHeightVertical: NSLayoutConstraint!
    
    private var currentOrientation = UIDevice.current.orientation
    private var previousOrientation = UIDevice.current.orientation
    private var isMarkCreationMode = false {
        didSet {
            createMarkContainer.isHidden = !isMarkCreationMode
            createMarkContainer.alpha = isMarkCreationMode ? 1 : 0
        }
    }
    
    private var openOptions: VMSOpenPlayerOptions = VMSOpenPlayerOptions()
    
    private var timeUpdaterTimer: Timer? = Timer()
    private var timelineDidScrollTask: DispatchWorkItem?
    private var liveArchiveTask: DispatchWorkItem?
    
    private var activityIndicator = UIActivityIndicatorView(style: .large)
    
    var isLive: Bool = true {
        didSet {
            delegate?.logPlayerEvent(event: isLive ? "SHOW_STREAM_LIFE" : "SHOW_STREAM_ARCHIVE")
            bottomView.isHidden = isLive
            optionsView.isHidden = !isLive
//            if viewModel.hasSound && !isRtsp {
//                soundButton.isHidden = !isLive
//                soundBottomButton.isHidden = isLive
//            }
        }
    }
    private var isPTZEnabled: Bool = false {
        didSet {
            ptzView.isHidden = true
            ptzButton.isHidden = !isPTZEnabled
            isPtz = false
        }
    }
    
    private var isArchiveDisabled: Bool = false
    private var isControlsHiden: Bool = false
    
    private var soundOn: Bool = false {
        didSet {
            let image = UIImage(named: soundOn ? "sound-on" : "sound-off", in: Bundle(for: VMSPlayerController.self), with: nil)
            soundButton.setImage(image, for: .normal)
            soundBottomButton.setImage(image, for: .normal)
        }
    }
    
    private var isPlaying: Bool = false {
        didSet {
            bottomView.configurePlayer(isPlaying, screenshotAllowed: viewModel.options.allowVibration, isMarkCreationMode: isMarkCreationMode)
            
            isPlaying ? self.videoLayer.play(hasSound: self.viewModel.hasSound, soundOn: self.soundOn) : self.videoLayer.pause(soundOn: self.soundOn)
            if isPlaying {
                videoLayer.setVideoSpeed(currentSpeed, from: self.topView.date)
            }
        }
    }
    
    private var isPtz = Bool()  {
        didSet {
            if isPtz {
                let image = UIImage(named: "ptz", in: Bundle(for: VMSPlayerController.self), with: nil)
                let tinted = image?.withRenderingMode(.alwaysTemplate)
                ptzButton.setImage(tinted, for: .normal)
                ptzButton.tintColor = .playerBlue
            } else {
                ptzButton.setImage(UIImage(named: "ptz", in: Bundle(for: VMSPlayerController.self), with: nil), for: .normal)
            }
        }
    }
    
    private var isRtsp: Bool {
//        return viewModel.getPlayerType(isLive: isLive) == .rtsp
        return true
    }
    
    private var currentSpeed: Double = 1.0
    
    private var endDate: Date?
    
    private var viewModel: VMSPlayerViewModel!
    
    private weak var delegate: VMSPlayerDelegate?
    
    public static func initialization(viewModel: VMSPlayerViewModel, delegate: VMSPlayerDelegate?, openOptions: VMSOpenPlayerOptions? = nil) -> VMSPlayerController {
        let storyboard = UIStoryboard.init(name: "VMSPlayer", bundle: Bundle(for: self))
        let controller = storyboard.instantiateViewController(withIdentifier: "VMSPlayerController") as! VMSPlayerController
        controller.viewModel = viewModel
        controller.delegate = delegate
        if let openOptions {
            controller.openOptions = openOptions
        }
        return controller
    }
    
    public func setOpenPlayerOptions(options: VMSOpenPlayerOptions) {
        self.openOptions = options
    }
    
    public func setDefaultQuality(quality: VMSStream.QualityType) {
        self.viewModel.setDefaultQiality(quality: quality)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
         Set isLive on start from open options
         need for correct UI
         TODO: Remove and check when DVR for RTSP is ready
        */
//        isLive = openOptions.openPlayerType == .live

        if !viewModel.hasPermission(.ArhivesPreviewDownload) {
            screenshotButton.isHidden = true
        }
        archiveCancelButton.setTitle(viewModel.translate(.Cancel), for: .normal)
        archiveDoneButton.setTitle(viewModel.translate(.Done), for: .normal)
        navigationItem.clearBackTitle()
        
        viewModel.delegate = self
        bottomView.delegate = self
        
        if viewModel.camera.archiveRanges == nil {
            self.reloadCameraInfo() // для открытия с виджета
        }
        
        // Hardcode. For now we are removing PTZ
        enablePTZ(viewModel.hasPermission(.Ptz))
        checkQualitySoundPTZ()
        
        configureDatePicker()
        
        topView.delegate = self
        timeline.delegate = self
//        if !isRtsp {
//            soundButton.isHidden = !viewModel.hasSound
//        } else {
        soundButton.isHidden = true
        soundBottomButton.isHidden = true
//        }
        qualityChanged()
        
//        if !viewModel.hasSound {
//            soundBottomButton.setImage(nil, for: .normal)
//        } else 
//        if isRtsp {
//            soundBottomButton.isHidden = true
//            soundBottomButton.setImage(nil, for: .normal)
//        } else {
//            soundBottomButton.isHidden = true
//        }
        DispatchQueue.main.async {
            self.videoLayer.setup(type: self.viewModel.getPlayerType(isLive: self.isLive), withDelegate: self)
        }
        
//        if !openOptions.isEventArchive && openOptions.archiveDate == nil {
//            getCameraStream()
//        }
        
        addRecognizers()
        ptzView.isHidden = true
        addObservers()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setNeedsStatusBarAppearanceUpdate()
        self.navigationController?.isNavigationBarHidden = true
        navigationController?.tabBarController?.tabBar.isHidden = true
        showLiveOptionsButton()
        topView.configure(
            viewModel.camera.name ?? "",
            archiveTitle: viewModel.translate(.Archive),
            date: topView.date ?? Date(), 
            isLiveAllowed: !openOptions.isLiveRestricted,
            isArchiveAllowed: (viewModel.hasPermission(.ArhivesShow) && !viewModel.options.onlyScreenshotMode)
        )
        
        if !viewModel.options.onlyScreenshotMode {
            viewModel.setMarksFilter(by: openOptions.markOptions.chosenMarksFilter)
            if openOptions.isEventArchive {
                openOptions.openPlayerType = .none
                archiveAction(onStart: true)
                showActivityIndicator()
                configureMarkStart()
            } else if openOptions.openPlayerType == .archive {
                openOptions.openPlayerType = .none
                archiveAction(onStart: true)
            } else if openOptions.openPlayerType == .live {
                openOptions.openPlayerType = .none
                liveAction(onStart: true)
            }
        } else {
            openOptions.openPlayerType = .none
            liveAction(onStart: true)
        }
                
        topView.isLive = isLive
        bottomView.isHidden = isLive
        ptzButton.layer.cornerRadius = ptzButton.bounds.height / 2
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let startOrientation = UIKit.UIApplication.shared.statusBarOrientation
        if (startOrientation == .landscapeLeft || startOrientation == .landscapeRight) && UIDevice.current.userInterfaceIdiom == .pad { // for ipad
            // MARK: - GravityButton Hardcode
            gravityButton.isHidden = true
        } else {
            gravityButton.isHidden = true
        }
        videoLayer.viewDidAppear()
        
        delegate?.playerDidAppear()
        if soundOn {
            videoLayer.setVolume(1)
        }
        if !openOptions.showEventEdit {
            dismissMarkCreation()
        }
    }
    
    private func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationChanged),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pausePlayer), name: NSNotification.Name.noConnectionError, object: nil) // когда нет интернета, чтобы останавливался плеер
        
        NotificationCenter.default.addObserver(forName: UIKit.UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] (notification) in
            guard let self = self else {return}
            if let date = topView.date, !isLive {
                self.timeline.setDate(date, isMarkCreationMode)
            }
            self.reloadCameraInfo()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadPermissions), name: NSNotification.Name.updateUserPermissions, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCamerasPermissions(_:)), name: NSNotification.Name.updateUserCameras, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getPushMarks(_:)), name: .updateMarks, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pushUpdateMark(_:)), name: .updateMark, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIKit.UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(interruptionNotification), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resumePlayback), name: NSNotification.Name.resumePlayback, object: nil)
    }
    
    private func configureMarkStart() {
        viewModel.resignApi()
        
        if viewModel.camera.archiveRanges == nil {
            // Came directly from events, need to load camera
            viewModel.getCameraInfo { [weak self] response in
                self?.continueConfigureMarkStart()
                
            } failure: { [weak self] error in
                self?.delegate?.playerDidReceiveError(message: error)
            }
        } else {
            continueConfigureMarkStart()
        }
    }
    
    private func continueConfigureMarkStart() {
        self.getMarkArchive()
        self.topView.date = self.openOptions.event?.from ?? self.openOptions.event?.createdAt ?? Date()
        // Came directly from events, need set timeline position
        if let eventFrom = openOptions.event?.from ?? self.openOptions.event?.createdAt {
            self.timeline.setDate(eventFrom, isMarkCreationMode)
        // Need set timeline position for set date position
        } else if let fromDate = self.openOptions.archiveDate {
            self.timeline.setDate(fromDate, isMarkCreationMode)
        }
        
        if self.openOptions.showEventEdit {
            self.isMarkCreationMode = true
            self.configureMarkCreationConstraints()
            self.markCreationController?.editMode = true
            self.markCreationController?.markToEdit = self.openOptions.event
            self.markCreationController?.nameField.text = self.openOptions.event?.title
            self.markCreationController?.date = self.openOptions.event?.from
            self.showActivityIndicator()
        }
    }
    
    @objc
    private func willResignActive() {
        viewModel.resignApi()
//        videoLayer.resignPlayer()
        self.isPlaying = false
        self.timeUpdaterTimer?.invalidate()
    }
    
    // когда получаем пуш на звонок, чтобы возобновить воспроизведение
    @objc
    func interruptionNotification(_ notification: Notification) {
        guard let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let interruption = AVAudioSession.InterruptionType(rawValue: type),
              interruption == .ended else {
            return
        }
        resumePlayback()
    }
    
    @objc
    func resumePlayback() {
        viewModel.resignApi()
        videoLayer.resignPlayer()
        if let date = topView.date, !isLive {
            self.timeline.setDate(date, isMarkCreationMode)
        }
        self.reloadCameraInfo()
    }
    
    private func addRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapHandler(_:)))
        videoLayer.addGestureRecognizer(tapGesture)
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        videoLayerScroll.addGestureRecognizer(doubleTap)
        
        addSwipeRecognizer(direction: .left)
        addSwipeRecognizer(direction: .right)
    }
    
    private func addSwipeRecognizer(direction: UISwipeGestureRecognizer.Direction) {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeAction(_:)))
        swipe.direction = direction
        videoLayer.addGestureRecognizer(swipe)
    }
    
    @objc private func getCameraArchive(_ notification: Notification) {
        guard let mark = notification.userInfo?["mark"] as? VMSEvent, let start = mark.from else {
            return
        }
        getCameraArchive(of: DateFormatter.serverUTC.string(from: start))
    }
    
    @objc private func updateCamerasPermissions(_ notification: Notification) {
        guard let notificationData = notification.userInfo?["data"] as? VMSCamerasUpdateSocket else {
            return
        }
        if notificationData.detached?.contains(viewModel.camera.id) ?? false {
            self.backAction(nil)
        }
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    public override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        videoLayer.setVolume(0)
    }
    
    deinit {
        delegate?.playerDidEnd()
        videoLayer.endPlayer()
        timeUpdaterTimer?.invalidate()
        timeUpdaterTimer = nil
        liveArchiveTask?.cancel()
        liveArchiveTask = nil
        timelineDidScrollTask?.cancel()
        timelineDidScrollTask = nil
        NotificationCenter.default.removeObserver(self)
    }
    // MARK: - Private
    
    private func enablePTZ(_ enabled: Bool)  {
        if viewModel.options.onlyScreenshotMode {
            isPTZEnabled = false
        } else {
            isPTZEnabled = enabled
        }
    }
    
    private func datePickerStartConfig() {
        if #available(iOS 13.4, *) {
            archiveDatePicker.preferredDatePickerStyle = .wheels
        }
        archiveDatePicker.locale = VMSLocalization.getCurrentLocale(language: viewModel.options.language)
        archivePickerView.isHidden = true
        archiveDatePicker.isHidden = false
        timePicker.isHidden = true
        archiveBackgroundView.alpha = 0.0
        archivePickerView.layer.cornerRadius = 8
        archivePickerBottom.constant = -archiveDatePicker.frame.height
        
        archiveDatePicker.addTarget(self, action: #selector(handleDatePickerTap), for: .editingDidBegin)
        archiveBackgroundView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(hideArchivePicker)))
        
        archiveDatePicker.setValue(UIColor.white, forKeyPath: "textColor")
        archiveDatePicker.minimumDate = timeline.stackView.firstStartDate
    }
    
    @objc func handleDatePickerTap() {
        archiveDatePicker.resignFirstResponder()
    }
    
    private func configureDatePicker(currentDate: Date = Date()) {
        datePickerStartConfig()
        archiveDatePicker.date = currentDate
        archiveDatePicker.maximumDate = Date()
        archiveDatePicker.datePickerMode = .dateAndTime
    }
    
    private func configureDatePickerDaySelection(currentDate: Date = Date()) {
        datePickerStartConfig()
        archiveDatePicker.date = currentDate
        archiveDatePicker.maximumDate = Date()
        archiveDatePicker.datePickerMode = .date
    }
    
    private func configureTimePicker(currentDate: Date = Date()) {
        timePickerStartConfig()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentDate)
        let minute = calendar.component(.minute, from: currentDate)
        let second = calendar.component(.second, from: currentDate)
        timePicker.selectRow(hour, inComponent: 0, animated: true)
        timePicker.selectRow(minute, inComponent: 1, animated: true)
        timePicker.selectRow(second, inComponent: 2, animated: true)
    }
    
    private func timePickerStartConfig() {
        archiveDatePicker.isHidden = true
        timePicker.isHidden = false
        archivePickerBottom.constant = -archiveDatePicker.frame.height
        timePicker.setValue(UIColor.white, forKeyPath: "textColor")
        
        archiveBackgroundView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(hideArchivePicker)))
    }
    
    @discardableResult func checkQualitySoundPTZ() -> (VMSStream.QualityType, Bool, Bool) {
            
        if viewModel.camera.nullStreams() != nil {
            self.delegate?.playerDidReceiveError(message: viewModel.translate(.ErrCameraInitLong))
        }
        
        let hasSound = checkSound()
        var hasPtz = Bool()
        if isPTZEnabled {
            ptzButton.isHidden = (viewModel.camera.hasPTZ ?? false) ? false : true
            isPtz = false // before click on ptzButton
            ptzView.isHidden = true
        }
        hasPtz = viewModel.camera.hasPTZ ?? false
        return (viewModel.currentQuality, hasSound,hasPtz)
    }
    
    @discardableResult func checkSound() -> Bool {
        if viewModel.needShowAskForNetDialogue() {
            viewModel.askForNet = true
            self.delegate?.isUserAllowForNet()
            let alert = UIAlertController.init(title: viewModel.translate(.TitleNoWifi), message: viewModel.translate(.MessageNoWifi), preferredStyle: .alert)
            alert.view.tintColor = UIColor.main
            
            alert.addAction(UIAlertAction.init(title: viewModel.translate(.Ok), style: .default, handler: nil))
            
            present(alert, animated: true, completion: nil)
        }

        var hasSound = Bool()
//        if (!isRtsp && !isLive && viewModel.camera.highStream()?.hasSound == true) || (!isRtsp && isLive && viewModel.currentStream?.hasSound == true) {
//            soundButton.isHidden = !isLive
//            soundBottomButton.isHidden = false
//            if viewModel.options.allowSoundOnStart {
//                soundOn = true
//            }
//            if soundOn && isPlaying {
//                videoLayer.setVolume(1)
//            }
//            
//            hasSound = true
//        } else if isRtsp {
            soundButton.isHidden = true
            soundBottomButton.isHidden = true
//            soundBottomButton.setImage(nil, for: .normal)
            hasSound = false
//        } else {
//            soundButton.isHidden = true
//            soundBottomButton.isHidden = true
//            soundBottomButton.setImage(nil, for: .normal)
//            hasSound = false
//        }
        return hasSound
    }
    
    @objc private func updateTimeLabel() {
        guard let date = videoLayer.playerDate() else {
            if !isLive {
                isPlaying = false
                timeUpdaterTimer?.invalidate()
                timeline.seekForNextAvailableTime()
                removeActivityIndicator()
            }
            return
        }
        
        if !isLive {
            enableButtons(true)
        }
        
        let newDateTimeinterval = date.timeIntervalSince1970
        let endingTimeinterval = TimeInterval(timeline.stackView.lastStripeEnd)
        
        if !isLive, (endingTimeinterval) <= newDateTimeinterval + 0.3 { // только для архива
            videoLayer.pause(soundOn: soundOn)
            isPlaying = false
            timeUpdaterTimer?.invalidate()
        }
        topView.date = date
        
//        if isMarkCreationMode {
//            markCreationController?.date = date
//            timeUpdaterTimer?.invalidate()
//            isPlaying = false
//        }
        
        if !isLive {
            timeline.setDate(date, isMarkCreationMode)
        }
        
        // Only for RTSP bacause we get date from stream
        if !isLive, isRtsp, timeline.currentDateIsOutOfRange(date: date) {
            isPlaying = false
            timeUpdaterTimer?.invalidate()
            timeline.seekForNextAvailableTime()
        }
    }
    
    private func setTimeUpdaterTimer() {
        timeUpdaterTimer?.invalidate()
        timeUpdaterTimer = Timer.scheduledTimer(timeInterval: 1.0 / currentSpeed, target: self, selector: #selector(self.updateTimeLabel), userInfo: nil, repeats: true)
    }
    
    @objc private func hideArchivePicker() {
        UIView.animate(withDuration: 0.3, animations: {
            self.archiveBackgroundView.alpha = 0.0
            self.archivePickerBottom.constant = -self.archiveDatePicker.frame.height
            self.view.layoutIfNeeded()
        }) { (completed) in
            self.archivePickerView.isHidden = true
        }
    }
    
    @objc private func hideArchivePickerWithCompletion(_ completion: @escaping (() -> Void)) {
        UIView.animate(withDuration: 0.3, animations: {
            self.archiveBackgroundView.alpha = 0.0
            self.archivePickerBottom.constant = -self.archiveDatePicker.frame.height
            self.view.layoutIfNeeded()
        }) { (completed) in
            self.archivePickerView.isHidden = true
            completion()
        }
    }
    
    private func enableRewindButtons() {
        guard let currentDate = timeline.getCurrentTimelineDate(),
            let startDate = viewModel.camera.startAt else {
                return
        }
        let endTimeinterval = TimeInterval(timeline.stackView.lastStripeEnd)
        let endDate = Date(timeIntervalSince1970: endTimeinterval)
        let date = min(max(currentDate, startDate), endDate)
        
        let dateMillis = date.timeIntervalSince1970
        let startMillis = startDate.timeIntervalSince1970
        let endMillis = endDate.timeIntervalSince1970
        
        let rightDiff = endMillis - dateMillis
        let leftDiff = dateMillis - startMillis
        
        bottomView.enableRewindButtons(rightDifference: rightDiff, leftDiference: leftDiff)
        
        timeline.nextMarkButton.isEnabled = rightDiff > 5
        timeline.prevMarkButton.isEnabled = leftDiff > 5
    }
    
    // MARK: - Get Video
    
    private func getCameraStream() {
        viewModel.playerErrorState = .normal
        if viewModel.hasPermission(.ArhivesPreviewDownload) {
            self.screenshotButton.isHidden = false
        }
        showActivityIndicator()
        switch viewModel.camera.userStatus {
        case .active, .none:
            break
        case .blocked:
            removeActivityIndicator()
            if openOptions.openPlayerType != .archive {
                viewModel.playerErrorState = .blocked
                self.delegate?.playerDidReceiveError(message: viewModel.getSnackPlayerStateError())
                self.videoLayer.resignPlayer()
                self.screenshotButton.isHidden = true
                return
            }
        }
        if viewModel.camera.isRestrictedLive ?? false {
            isPlaying = false
            viewModel.playerErrorState = .liveRestricted
            removeActivityIndicator()
            self.screenshotButton.isHidden = true
            self.videoLayer.endPlayer()
//            self.videoLayer.setup(type: viewModel.getPlayerType(), withDelegate: self)
            return
        }
        switch viewModel.camera.status {
        case .empty,.inactive,.initial:
            removeActivityIndicator()
            if openOptions.openPlayerType != .archive {
                viewModel.setNewPlayerState(cameraStatus: viewModel.camera.status)
                self.delegate?.playerDidReceiveError(message: viewModel.getSnackPlayerStateError())
                self.videoLayer.resignPlayer()
                self.screenshotButton.isHidden = true
                return
            }
        default: break
        }
        viewModel.getCameraStream()
    }
    
    private func getCameraArchive(of dateString: String, completion: @escaping (() -> Void) = {} ) {
//        var dateString = dateString
//        if let fromDate = openOptions.archiveDate {
//            dateString = DateFormatter.serverUTC.string(from: fromDate)
//            self.timeline.setDate(fromDate, isMarkCreationMode)
//            openOptions.archiveDate = nil
//        }
        
        if viewModel.hasPermission(.ArhivesPreviewDownload) {
            self.bottomView.screenshotButton.alpha = 1
        }
        viewModel.playerErrorState = .normal
        switch viewModel.camera.userStatus {
        case .active, .none:
            break
        case .blocked:
            viewModel.playerErrorState = .blocked
            self.delegate?.playerDidReceiveError(message: viewModel.getSnackPlayerStateError())
            removeActivityIndicator()
            bottomView.screenshotButton.alpha = 0
            videoLayer.blockArchive()
            return
        }
        switch viewModel.camera.status {
        case .empty, .inactive, .initial, .active:
            if viewModel.camera.archiveRanges?.count == 0 {
                viewModel.playerErrorState = (viewModel.camera.isRestrictedArchive ?? false) ? .archiveRestricted : .archiveError
                removeActivityIndicator()
                bottomView.screenshotButton.alpha = 0
                videoLayer.blockArchive()
                return
            } else {
                break
            }
        case .partial:
            if viewModel.camera.highStream() == nil {
                viewModel.playerErrorState = .archiveError
                removeActivityIndicator()
                bottomView.alpha = 0
                videoLayer.blockArchive()
                return
            }
        default:
            break
        }
        enableButtons(false)
        showActivityIndicator()

        if viewModel.hasPermission(.MarksIndex), viewModel.currentEventOption != .none && !self.openOptions.showEventEdit && !self.isLive && !self.isMarkCreationMode, let date = DateFormatter.serverUTC.date(from: dateString) {
            self.getCameraMarks(date: date)
        }
        let newDate = DateFormatter.serverUTC.date(from: dateString) ?? Date()
        self.topView.date = newDate
        
        viewModel.getCameraArchive(newDate) { [weak self] url, start in
            guard let self = self else { return }
            self.delegate?.playerDidReceiveInfo(message: "VMSPlayerController received archive URL:\n\(url)")
            var urlString = url
            if urlString.last == "&" {
                urlString = String(urlString.dropLast())
            }
            guard let url = URL(string: urlString) else {
                self.delegate?.playerDidReceiveError(message: self.viewModel.translate(.ErrCantLoadArchive))
                self.removeActivityIndicator()
                self.bottomView.screenshotButton.alpha = 0
                return
            }
            self.viewModel.playerErrorState = .normal
            self.showTimeline()
            self.videoLayer.playArchiveUrl(url, speed: self.currentSpeed)
            self.isPlaying = true
            self.videoLayer.setVolume(self.soundOn ? 1 : 0)
            self.setTimeUpdaterTimer()
            
            if self.timeline.isEnd() {
                self.topView.date = start
                self.enableButtons(true)
                self.removeActivityIndicator()
            } else {
//                if self.isMarkCreationMode {
////                    self.isPlaying = false
//                } else {
//                    self.setTimeUpdaterTimer()
//                }
            }
            completion()
        }
    }
    
    private func reloadCameraBeginning() {
        let group = DispatchGroup()
        
        group.enter()
        viewModel.getCameraInfo { [weak self] cam in
            guard let self = self else { return }
            self.timeline.removeMarks()
            self.currentSpeed = 1
            self.newCameraConfigure()
            self.configureDatePicker()
            self.videoLayer.resignPlayer()
            self.topView.nameLabel.text = cam.name
            group.leave()
        } failure: { [weak self] error in
            self?.delegate?.playerDidReceiveError(message: error)
            group.leave()
        }
        
        group.notify(queue: .main) {
            if let startAt = self.viewModel.camera.startAt {
                self.getCameraArchive(of: DateFormatter.serverUTC.string(from: startAt))
            }
        }
    }
    
    public override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        
        // Only handle observations for the playerItemContext

        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status

            // Get the status change from the change dictionary
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = AVPlayerItem.Status.unknown
            }

            // Switch over the status
            switch status {
            case .readyToPlay:
                self.viewModel.playerErrorState = .normal
                self.removeActivityIndicator()
            // Player item is ready to play.
            case .failed:
            // Player item failed. See error.
                enableButtons(true)
                removeActivityIndicator()
                self.viewModel.playerErrorState = .unknown
                self.delegate?.playerDidReceiveError(message: viewModel.translate(.ServerError))
            case .unknown:
                // Player item is not yet ready.
                break
            @unknown default:
                break
            }
        }
    }
    
    private func reloadCameraInfo() {
        
        viewModel.getCameraInfo { [weak self] response in
            guard let self = self else { return }
            self.viewModel.playerErrorState = .normal
            self.checkQualitySoundPTZ()
            self.timeline.removeMarks()
            self.currentSpeed = 1
            self.newCameraConfigure()
            self.configureDatePicker()
            self.isLive ? self.liveAction(onStart: false) : self.archiveAction(onStart: false)
            self.topView.nameLabel.text = self.viewModel.camera.name
        } failure: { [weak self] error in
            self?.delegate?.playerDidReceiveError(message: error)
        }
    }
    
    private func newCameraConfigure() {
        if viewModel.hasPermission(.ArhivesPreviewDownload) {
            bottomView.screenshotButton.alpha = 1
            screenshotButton.isHidden = false
        }
        switch viewModel.camera.userStatus {
        case .active, .none:
            break
        case .blocked:
            viewModel.playerErrorState = .blocked
            bottomView.screenshotButton.alpha = 0
            screenshotButton.isHidden = true
            return
        }
        
        if isLive {
            switch viewModel.camera.status {
            case .inactive,.initial,.empty:
                viewModel.setNewPlayerState(cameraStatus: viewModel.camera.status)
                screenshotButton.isHidden = true
                self.delegate?.playerDidReceiveError(message: viewModel.getSnackPlayerStateError())
            default:
                self.getCameraStream()
            }
        } else {
            
            if let time = self.timeline.currentDate {
                self.timeline.shouldAskNewArchive = false
                self.timeline.configure([viewModel.camera], previousTime: time, setStartZoom: false, allowVibration: viewModel.options.allowVibration)
            } else {
                let time = Date() // for inactive cameras
                self.timeline.shouldAskNewArchive = true
                self.timeline.configure([viewModel.camera], previousTime: time, setStartZoom: false, allowVibration: viewModel.options.allowVibration)
            }
            
            if viewModel.camera.archiveRanges?.count == 0 {
                self.viewModel.playerErrorState = (viewModel.camera.isRestrictedArchive ?? false) ? .archiveRestricted : .archiveError
                self.bottomView.screenshotButton.alpha = 0
                return
            }
            
            guard let date = self.topView.date else { return }
            
            if viewModel.hasPermission(.MarksIndex), viewModel.currentEventOption != .none {
                getCameraMarks(date: date)
            }
            
            if self.timeline.shouldAskNewArchive && !self.isLive {
                self.getCameraArchive(of: DateFormatter.serverUTC.string(from: date))
            }
        }
    }
    
    @objc private func getPushMarks(_ notification: Notification) {
        getCameraMarks(date: topView.date ?? Date())
    }
    
    private func getCameraMarks(date: Date, completion: @escaping (() -> Void) = {}) {
        if viewModel.currentEventOption == .none {
            return
        }
        let secondsOnHalfScreen = Int((timeline.stackView.screenDuration / timeline.videoScrollView.transform.a) / 2)
        let calendar = Calendar.current
        if viewModel.hasPermission(.MarksIndex), let fromDate = calendar.date(byAdding: .second, value: -secondsOnHalfScreen, to: date),
           let endDate = calendar.date(byAdding: .second, value: secondsOnHalfScreen + 3600, to: date) {
            viewModel.getCameraEvents(from: fromDate, to: endDate) { [weak self] marks in
                guard let self = self else { return }
                if self.viewModel.currentEventOption != .none {
                    self.timeline.configureMarks(self.viewModel.cameraEvents, hideTimelabel: false)
                }
                completion()
            }
        }
    }
    
    @objc private func pushUpdateMark(_ notification: Notification) {
        guard let updateMark = notification.userInfo?["data"] as? VMSEvent else { return }
        self.getCameraMarks(date: topView.date ?? Date()) { [weak self] in
            guard let self else { return }
            if updateMark.id == self.timeline.timeLabel.mark?.id {
                self.timeline.timeLabel.mark = updateMark
                self.timeline.markLabelVisible = true
                self.timeline.performHideMark()
            }
        }
    }
    
    
    // MARK: - Observers functions
    
    @objc func pausePlayer() {
        isPlaying = false
        timeUpdaterTimer?.invalidate()
        removeActivityIndicator()
    }
    
    @objc func reloadPermissions() {
        if viewModel.hasPermission(.Ptz), viewModel.hasPtz  {
            enablePTZ(true)
        } else {
            enablePTZ(false)
        }
        
        if viewModel.hasPermission(.ArhivesPreviewDownload) {
            screenshotButton.isHidden = false
            bottomView.screenshotButton.alpha = 1
        } else {
            screenshotButton.isHidden = true
            bottomView.screenshotButton.alpha = 0
        }
        
        let currentSpeedBuffer = self.currentSpeed
        
        if !viewModel.hasPermission(.MarksIndex) {
            self.timeline.removeMarks()
            self.currentSpeed = currentSpeedBuffer
            viewModel.currentEventOption = .none
        } else {
            if let date = topView.date {
                getCameraMarks(date: date)
            }
            self.currentSpeed = currentSpeedBuffer
        }
        
        if viewModel.hasPermission(.MarksIndex) || !(viewModel.camera.highStream() == nil || viewModel.camera.lowStream() == nil)  {
            liveOptionsButton.isHidden = false
        } else {
            liveOptionsButton.isHidden = true
        }
        
        showLiveOptionsButton()
        
        if !viewModel.hasPermission(.MarksStore) || !viewModel.hasPermission(.MarksIndex) {
            if isMarkCreationMode {
                isMarkCreationMode = false
                configureMarkCreationConstraints()
            }
        }
        topView.reloadPermissions(isArchiveAllowed: viewModel.hasPermission(.ArhivesShow))
    }
    
    private func showLiveOptionsButton() {
        if (viewModel.hasPermission(.MarksIndex) || !(viewModel.camera.highStream() == nil || viewModel.camera.lowStream() == nil)) && !viewModel.options.onlyScreenshotMode {
            liveOptionsButton.isHidden = false
        } else {
            liveOptionsButton.isHidden = true
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if isMarkCreationMode && (UIApplication.shared.statusBarOrientation == .portrait || UIApplication.shared.statusBarOrientation == .portraitUpsideDown) || (UIDevice.current.userInterfaceIdiom == .pad && (UIApplication.shared.statusBarOrientation == .landscapeLeft || UIApplication.shared.statusBarOrientation == .landscapeRight)) {
            let userInfo = notification.userInfo
            guard let endFrame = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                  let duration = userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
                let markNameFieldFrameBottom = markCreationController?.nameField.frame.maxY else {return}
            
            var safeAreaBottom: CGFloat?
            if #available(iOS 11.0, *) {
                safeAreaBottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom
            }
            let viewHeight: CGFloat = isSmallIPhone() ? 200 : 240
            let keyboardHeight = endFrame.height + (safeAreaBottom ?? 0)
            let bottomViewHeight = self.bottomView.frame.height
            let containerTop = viewHeight + createMarkBottomVerticalConstraint.constant + (safeAreaBottom ?? 0) + bottomViewHeight
            let fieldCoordinate = containerTop - markNameFieldFrameBottom
            if keyboardHeight >= fieldCoordinate {
                var dif = keyboardHeight - fieldCoordinate
                if dif == 0 {
                    dif = 50
                }
                switch UIDevice.current.userInterfaceIdiom {
                case .pad:
                    createMarkTopHorizontal.constant -= dif
                case .phone:
                    createMarkBottomVerticalConstraint.constant += dif
                default:
                    break
                }
                self.view.setNeedsUpdateConstraints()
                UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: self.view.layoutSubviews, completion: nil)
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        configureMarkCreationConstraints()
        let userInfo = notification.userInfo
            guard let duration = userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {return}
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: self.view.layoutSubviews, completion: nil)
    }

    
    
    // MARK: - Orientation
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        timeline.viewWillTransition(to: size, with: coordinator)
        videoLayerScroll.zoomScale = 1
        
        coordinator.animateAlongsideTransition(in: self.view, animation: { [weak self] (context) in
            guard let self = self else { return }
            if self.isMarkCreationMode {
                self.configureMarkCreationConstraints()
            }
            self.videoLayer.updatePlayerFrame()
            self.videoLayer.needsLayout()
            self.view.layoutIfNeeded()
            self.view.layoutSubviews()
            }, completion: { completion in
                if !self.isLive {
                    self.timeline.orientationChanged()
                    let date = self.topView.date ?? Date()
                    self.timeline.setDate(date, false)
                }
                self.videoLayer.setGravityResizeAspect(true)
                self.videoLayer.updatePlayerFrame()
                self.timeline.datesCollection.reloadData()
                self.view.layoutIfNeeded()
        })
    }
    
    @objc private func orientationChanged() {
        var bufferForPortraitOrLandscape = UIDevice.current.orientation
        if previousOrientation == .portrait || previousOrientation == .landscapeRight || previousOrientation == .landscapeLeft || previousOrientation == .portraitUpsideDown {
            bufferForPortraitOrLandscape = previousOrientation
        }
        
        previousOrientation = currentOrientation
        currentOrientation = UIDevice.current.orientation
        
        if currentOrientation == .landscapeRight || currentOrientation == .landscapeLeft {
            if (previousOrientation == .faceUp || previousOrientation == .faceDown) && (bufferForPortraitOrLandscape != .portrait && bufferForPortraitOrLandscape != .portraitUpsideDown) {
                return
            }
        } else {
            if (previousOrientation == .faceUp || previousOrientation == .faceDown) && (bufferForPortraitOrLandscape != .landscapeRight && bufferForPortraitOrLandscape != .landscapeLeft) {
                return
            }
        }
        
        if currentOrientation == .faceUp || currentOrientation == .faceDown || (currentOrientation == .portraitUpsideDown && UIDevice.current.userInterfaceIdiom == .phone) {
            return
        }
        
        if currentOrientation == .landscapeLeft || currentOrientation == .landscapeRight {
            if UIDevice.current.userInterfaceIdiom == .pad {
                // MARK: - GravityButton Hardcode
                gravityButton.isHidden = true
            }
        } else {
            if UIDevice.current.userInterfaceIdiom == .pad {
                gravityButton.isHidden = true
            }
        }
        videoLayer.setGravityResizeAspect(true)
    }
    
    // MARK: - Video Options
    
    fileprivate func showOptions(_ type: VideoOptions.OptionsViewType) {
        switch type {
        case .live(_, _, _), .archive(_, _, _, _):
            let options = VideoOptions.configure(type: type, viewModel: viewModel, translations: viewModel.translations, allMarkTypes: viewModel.options.markTypes, allowVibration: viewModel.options.allowVibration, videoRates: viewModel.options.videoRates, separationHandler: { result in
                switch result {
                case .eventsList:
                    self.showEventsList()
                case .quality:
                    self.showOptions(.quality(self.viewModel.currentQuality))
                case .speed:
                    self.delegate?.logPlayerEvent(event: "SHOW_PLAYBACK_SPEED")
                    self.showOptions(.speed(self.currentSpeed, self.viewModel.currentStreamCodecType))
                case .events:
                    self.showOptions(.events(self.viewModel.currentEventOption))
                case .downloadArchive:
                    self.showDownloadArchive()
                case .playback:
                    self.showOptions(.playback(self.viewModel.getPlayerType(isLive: self.isLive)))
                }
            })
            self.present(options, animated: true, completion: nil)
        case .quality(_), .speed(_, _), .playback(_):
            let options = VideoOptions.configure(type: type, viewModel: viewModel, translations: viewModel.translations, allMarkTypes: viewModel.options.markTypes, allowVibration: viewModel.options.allowVibration, videoRates: viewModel.options.videoRates, singleSelectionHandler: { result in
                switch result {
                case .speed(let chosenSpeed):
                    if self.timeline.isEnd() {
                        return
                    }
                    self.currentSpeed = chosenSpeed
                    self.isPlaying = false
                    self.showActivityIndicator()
                    self.isPlaying = true
                    self.setTimeUpdaterTimer()
                case .quality(let chosenQuality):
                    let newQuality = chosenQuality == .high ? VMSStream.QualityType.high : VMSStream.QualityType.low
                    if self.viewModel.currentQuality == newQuality {
                        return
                    }
                    self.viewModel.currentQuality = newQuality
                    self.delegate?.logPlayerEvent(event: self.viewModel.currentQuality == .high ? "TAP_VIDEO_QUALITY_HIGH" : "TAP_VIDEO_QUALITY_LOW")
                    self.delegate?.qualityChanged(quality: newQuality)
                    self.liveAction(onStart: false)
                case .playback(let type):
                    self.viewModel.setPlayerType(type)
                case .none: break
                }
            })
            self.present(options, animated: true, completion: nil)
        case .events(_):
            let options = VideoOptions.configure(type: type, viewModel: viewModel, translations: viewModel.translations, allMarkTypes: viewModel.options.markTypes, allowVibration: viewModel.options.allowVibration, videoRates: viewModel.options.videoRates, multiSelectionHandler: { result in
                self.viewModel.currentEventOption = result
                switch result {
                case .all:
                    if self.viewModel.hasPermission(.MarksIndex) {
                        if !self.isMarkCreationMode {
                            self.getCameraMarks(date: self.topView.date ?? Date())
                        }
                    } else {
                        self.timeline.removeMarks()
                    }
                    self.delegate?.marksFiltered(markTypes: self.viewModel.options.markTypes)
                case .none:
                    self.timeline.removeMarks()
                    self.delegate?.marksFiltered(markTypes: [])
                case .types(let types):
                    self.getCameraMarks(date: self.topView.date ?? Date())
                    self.delegate?.marksFiltered(markTypes: self.viewModel.options.markTypes.filter{types.contains($0.typeName())})
                }
            })
            self.present(options, animated: true, completion: nil)
        }
    }
    
    private func showEventsList() {
        delegate?.logPlayerEvent(event: "SHOW_MARK_LIST")
        delegate?.gotoEventsList(camera: viewModel.camera)
    }
    
    // MARK: - Download Archive
    
    private func showDownloadArchive() {
        self.delegate?.logPlayerEvent(event: "SHOW_DOWNLOAD_ARCHIVE")
        self.dismiss(animated: true, completion: nil)
        self.pausePlayer()
        let optionsController = DownloadArchiveController.initialization(camera: viewModel.camera, startDate: topView.date, locale: VMSLocalization.getCurrentLocale(language: viewModel.options.language), translations: viewModel.translations, api: viewModel.playerApi)
        optionsController.delegate = self
        self.present(optionsController, animated: true, completion: nil)
    }
    
    // MARK: - Gestures
    
    @objc private func tapHandler(_ sender: UITapGestureRecognizer) {
        topView.isHidden.toggle()
        isControlsHiden.toggle()
        if !isLive {
            if !isArchiveDisabled {
                bottomView.isHidden = topView.isHidden
            }
        } else {
            optionsView.isHidden = topView.isHidden
            if isPtz && !topView.isHidden && isPTZEnabled{
                ptzView.isHidden = false
            } else {
                ptzView.isHidden = true
            }
            
//            if let stream = viewModel.currentStream, stream.hasSound, !isRtsp {
//                soundButton.isHidden = topView.isHidden
//                soundBottomButton.isHidden = bottomView.isHidden
//        } else if videoLayer.hasSound(), isRtsp {
            if videoLayer.hasSound() {
                soundButton.isHidden.toggle()
                soundBottomButton.isHidden.toggle()
            }
        }
        self.view.endEditing(true)
    }
    
    @objc func doubleTap(_ sender: UITapGestureRecognizer) {
        if (videoLayerScroll.zoomScale > videoLayerScroll.minimumZoomScale) {
            videoLayerScroll.setZoomScale(videoLayerScroll.minimumZoomScale, animated: true)
        } else {
            let zoomRect = zoomRectForScale(scale: videoLayerScroll.maximumZoomScale / 2.0, center: sender.location(in: sender.view))
            videoLayerScroll.zoom(to: zoomRect, animated: true)
        }
    }
    
    func zoomRectForScale(scale : CGFloat, center : CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = videoLayer.frame.size.height / scale
        zoomRect.size.width  = videoLayer.frame.size.width  / scale
        let newCenter = videoLayer.convert(center, from: self.view)
        zoomRect.origin.x = newCenter.x - ((zoomRect.size.width / 2.0))
        zoomRect.origin.y = newCenter.y - ((zoomRect.size.height / 2.0))
        return zoomRect
    }
    
    // MARK: - Actions 
    
    @IBAction func backAction(_ sender: Any?) { // Использовать всегда вместо popViewController
        timeline.stackView.isHidden = true
        timeline.datesCollection.isHidden = true
        timeline.removeMarks()
        timeline.stackView.isHidden = true
        timeUpdaterTimer?.invalidate()
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func playAction(_ sender: Any?) {
        if !isLive && timeline.isEnd() || isMarkCreationMode {
            return
        }
        isPlaying.toggle() // play actions + speed configure now is in isPlaying's didSet
        if isPlaying {
            viewModel.playerErrorState = .normal
            delegate?.logPlayerEvent(event: "TAP_ARCHIVE_PLAY")
            setTimeUpdaterTimer()
            if isRtsp {
                showActivityIndicator()
            }
        } else {
            delegate?.logPlayerEvent(event: "TAP_ARCHIVE_PAUSE")
            timeUpdaterTimer?.invalidate()
        }
        UIDevice.vibrate(isAllowed: viewModel.options.allowVibration)
    }
    
    @IBAction func soundAction(_ sender: Any?) {
//        if (!isLive && viewModel.camera.highStream()?.hasSound == true) || (isLive && viewModel.currentStream?.hasSound == true) {
        soundOn.toggle()
        viewModel.isSoundOn = soundOn
        delegate?.soundChanged(isOn: soundOn)
        if isPlaying || isRtsp {
            videoLayer.setVolume(soundOn ? 1 : 0)
        }
        UIDevice.successVibration(isAllowed: viewModel.options.allowVibration)
//        }
    }
    
    @IBAction func screenshotAction(_ sender: Any?) {
        guard
            let dateString = topView.dateLabel.text,
            let _ = DateFormatter.yearMonthDay.date(from: dateString) else {
            self.delegate?.playerDidReceiveError(message: viewModel.translate(.ErrCommonShort))
            return
        }
        UIDevice.vibrate(isAllowed: viewModel.options.allowVibration)
        videoLayer.getScreenshot()
    }
    
    private func enableButtons(_ enable: Bool) {
        if enable {
            enableRewindButtons()
        } else {
            bottomView.enableButtons(enable)
            
            timeline.nextMarkButton.isEnabled  = enable
            timeline.prevMarkButton.isEnabled  = enable
        }
    }
    
    // MARK: - ActivityIndicator
    
    private func showActivityIndicator() {
        if activityIndicator.superview != nil {
            removeActivityIndicator()
        }
        self.view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        activityIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        activityIndicator.startAnimating()
    }
    
    private func removeActivityIndicator() {
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }
    
    // MARK: - Buttons
    
    @IBAction func videoGravityAction(_ sender: Any) {
        videoLayer.toggleGravityResizeAspect()
    }
    
    @IBAction func liveOptionsAction(_ sender: Any?) {
        showOptions(.live(viewModel.currentQuality, (viewModel.camera.highStream() != nil && viewModel.camera.lowStream() != nil), viewModel.getPlayerType(isLive: isLive)))
        UIDevice.vibrate(isAllowed: viewModel.options.allowVibration)
    }
    
    @IBAction func ptzAction(_ sender: Any) {
        
        if isPTZEnabled {
            ptzView.isHidden.toggle()
            isPtz = !ptzView.isHidden
            ptzView.configure(allowVibration: viewModel.options.allowVibration, cameraId: viewModel.camera.id, api: viewModel.playerApi)
            UIDevice.vibrate(isAllowed: viewModel.options.allowVibration)
        }
    }
    
    @IBAction func datePickerTap(_ sender: Any?) {
        delegate?.logPlayerEvent(event: "SHOW_CALENDAR")
        configureDatePicker()
        openDatePicker(sender)
    }
    
    func openDatePicker(_ sender: Any?) {
        archiveDatePicker.isHidden = false
        timePicker.isHidden = true
        archivePickerView.isHidden = false
        UIDevice.vibrate(isAllowed: viewModel.options.allowVibration)
        UIView.animate(withDuration: 0.3) {
            self.archiveBackgroundView.alpha = 1.0
            self.archivePickerBottom.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    func timePickerAction() {
        self.isPlaying = false
        archivePickerView.isHidden = false
        timePicker.isHidden = false
        UIDevice.vibrate(isAllowed: viewModel.options.allowVibration)
        UIView.animate(withDuration: 0.3) {
            self.archiveBackgroundView.alpha = 1.0
            self.archivePickerBottom.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func rewindRight(_ sender: Any?) {
        delegate?.logPlayerEvent(event: "TAP_PLAYBACK_END")
        timeline.setToEnd()
        UIDevice.vibrate(isAllowed: viewModel.options.allowVibration)
    }
    
    @IBAction func rewindLeft(_ sender: Any?) {
        delegate?.logPlayerEvent(event: "TAP_PLAYBACK_START")
        timeline.setToBeginning()
        UIDevice.vibrate(isAllowed: viewModel.options.allowVibration)
    }
    
    private func combineDateAndTime(dayDate: Date, timeDate: Date) -> Date? {
        let calendar = Calendar.current
        let dayComponents = calendar.dateComponents([.year,.month,.day], from: dayDate)
        let timeComponents = calendar.dateComponents([.hour,.minute,.second], from: timeDate)
        var mergedComponents = DateComponents()
        mergedComponents.year = dayComponents.year
        mergedComponents.month = dayComponents.month
        mergedComponents.day = dayComponents.day
        mergedComponents.hour = timeComponents.hour
        mergedComponents.minute = timeComponents.minute
        mergedComponents.second = timeComponents.second
        return calendar.date(from: mergedComponents)
    }
    
    @IBAction func donePickerAction(_ sender: Any?) {
        hideArchivePickerWithCompletion {
            UIDevice.successVibration(isAllowed: self.viewModel.options.allowVibration)
            var date = Date()
            if !self.archiveDatePicker.isHidden {
                if self.archiveDatePicker.datePickerMode == .date {
                    let dayDate = self.archiveDatePicker.date
                    let currentDate = self.markCreationController?.date
                    if let currentDate = currentDate, let endDate = self.endDate, let combinedDate = self.combineDateAndTime(dayDate: dayDate, timeDate: currentDate) {
                        if combinedDate > endDate {
                            date = endDate
                        } else {
                            date = combinedDate
                        }
                    }
                } else {
                    date = self.archiveDatePicker.date
                }
            } else if !self.timePicker.isHidden {
                let currentDayDate = self.markCreationController?.date
                let hour = self.timePicker.selectedRow(inComponent: 0)
                let minute = self.timePicker.selectedRow(inComponent: 1)
                let second = self.timePicker.selectedRow(inComponent: 2)
                let calendar = Calendar.current
                var dateComponents = DateComponents()
                dateComponents.hour = hour
                dateComponents.minute = minute
                dateComponents.second = second
                if let timeDate = calendar.date(from: dateComponents), let endDate = self.endDate, let dayDate = currentDayDate, let combinedDate = self.combineDateAndTime(dayDate: dayDate, timeDate: timeDate) {
                    if combinedDate > endDate {
                        date = endDate
                    } else {
                        date = combinedDate
                    }
                } else {
                    if let markDate = self.markCreationController?.date {
                        date = markDate
                    }
                }
            }
            
            self.timeline.setDate(date, true)
            self.timelineDidScroll(to: DateFormatter.serverUTC.string(from: date))
//            let archiveDate = DateFormatter.serverUTC.string(from: date)
//            self.getCameraArchive(of: archiveDate) { [weak self] in
//                guard let self = self else {return}
//                if self.isMarkCreationMode {
//                    self.markCreationController?.date = date
//                    if let oldMark = self.timeline.timeLabel.mark {
//                        oldMark.from = date
//                        self.timeline.timeLabel.mark = oldMark
//                    } else {
//                        
//                    }
//                    self.pausePlayer()
//                }
//            }
            self.configureDatePicker()
        }
    }

    
    @IBAction func cancelPickerAction(_ sender: Any?) {
        hideArchivePicker()
    }
    
    @IBAction func optionsAction(_ sender: Any?) {
        showOptions(.archive(currentSpeed, viewModel.currentEventOption, !openOptions.markOptions.disableOption, .rtspH264))
        UIDevice.vibrate(isAllowed: viewModel.options.allowVibration)
    }
    
    // MARK: - Swipe
    
    @objc func swipeAction(_ sender: UISwipeGestureRecognizer) {
        self.view.endEditing(true)
        if !viewModel.canSwipeCameras() {
            UIDevice.warningVibration(isAllowed: viewModel.options.allowVibration)
            return
        }
        guard let index = viewModel.getCameraIndexInGroup() else { return }
        guard sender.direction == .right || sender.direction == .left else { return }
        
        removeActivityIndicator()
        var camera: VMSCamera
        if sender.direction == .right {
            if index == 0 {
                // First Camera
                UIDevice.warningVibration(isAllowed: viewModel.options.allowVibration)
                return
            }
            camera = viewModel.groupCameras[index - 1]
        } else {
            if index == viewModel.groupCameras.count - 1 {
                // Last Camera
                UIDevice.warningVibration(isAllowed: viewModel.options.allowVibration)
                return
            }
            camera = viewModel.groupCameras[index + 1]
        }
        
        isPlaying = false
        timeUpdaterTimer?.invalidate()
        
        delegate?.dismissPlayerErrors()
        UIDevice.vibrate(isAllowed: viewModel.options.allowVibration)
        let askForNet = viewModel.askForNet
        let isSoundOn = viewModel.isSoundOn
        viewModel = VMSPlayerViewModel(camera: camera, groupCameras: viewModel.groupCameras, user: viewModel.user, translations: viewModel.translations, playerApi: viewModel.playerApi, options: viewModel.options, currentEventOption: viewModel.currentEventOption)
        viewModel.isSoundOn = isSoundOn
        viewModel.askForNet = askForNet
        viewModel.delegate = self
        reloadCameraInfo()
        
        if camera.status == .inactive {
            addSwipeRecognizer(direction: .left)
            addSwipeRecognizer(direction: .right)
        } else {
            if let gestures = self.view.gestureRecognizers {
                for gesture in gestures {
                    if let swipe = gesture as? UISwipeGestureRecognizer {
                        self.view.removeGestureRecognizer(swipe)
                    }
                }
            }
        }
    }
    
    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? CreateMarkController, segue.identifier == "createMarkSegue" {
            markCreationController = dest
            dest.markCreationDelegate = self
            dest.translations = viewModel.translations
            dest.language = viewModel.options.language
        }
    }
    
    // MARK: - Comfigure UI
    
    private func setLiveUI() {
        viewModel.playerErrorState = .normal
        delegate?.dismissPlayerErrors()
        isLive = true
        timeline.isArchive = false
        videoLayerScroll.setZoomScale(1, animated: true)
        checkQualitySoundPTZ()
    }
    
    private func setArchiveUI() {
        viewModel.playerErrorState = .normal
        delegate?.dismissPlayerErrors()
        isLive = false
        timeline.isArchive = true
        ptzView.isHidden = true
        isPtz = false
        videoLayerScroll.setZoomScale(1, animated: true)
        timeline.configure([viewModel.camera], previousTime: nil, setStartZoom: true, allowVibration: viewModel.options.allowVibration)
        configureDatePicker()
        checkSound()
        switch viewModel.camera.cameraStatus {
        case .active:
            configureTimelineEnd()
        case .inactive, .initial, .empty:
            configureInactiveTimeline()
        case .partial:
            if viewModel.camera.highStream() == nil {
                configureInactiveTimeline()
            } else {
                configureTimelineEnd()
            }
        }
    }
}

// MARK: - Header Delegate

extension VMSPlayerController: VideoHeaderDelegate {
    
    func liveAction(onStart: Bool) {
        self.liveArchiveTask?.cancel()
        
        setLiveUI()
        videoLayer.reloadPlayer()
        if (videoLayer.currentPlayerType() != viewModel.getPlayerType(isLive: isLive)) {
            self.videoLayer.endPlayer()
            self.videoLayer.remove()
            self.videoLayer.setup(type: viewModel.getPlayerType(isLive: isLive), withDelegate: self)
        }
        
        UIDevice.vibrate(isAllowed: self.viewModel.options.allowVibration)
        
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.getCameraStream()
            self.endDate = nil
            self.dismissMarkCreation()
        }
        
        self.liveArchiveTask = task
        
        //1.0 is the wait or idle time for execution of the function liveAction
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + (onStart ? 0 : 1), execute: task)
    }
    
    func archiveAction(onStart: Bool) {
        self.liveArchiveTask?.cancel()

        setArchiveUI()
        videoLayer.reloadPlayer()

        if (videoLayer.currentPlayerType() != viewModel.getPlayerType(isLive: isLive)) {
            self.videoLayer.endPlayer()
            self.videoLayer.remove()
            self.videoLayer.setup(type: viewModel.getPlayerType(isLive: isLive), withDelegate: self)
        }
        
        if !(viewModel.camera.isRestrictedArchive ?? false) && openOptions.isEventArchive == false {
            let date = Date(timeIntervalSince1970: TimeInterval(timeline.stackView.lastStripeEnd))
            
            let calendar = Calendar.current
            guard let newDate = calendar.date(byAdding: .minute, value: -10, to: date) else { return }
            timeline.setDate(newDate, false)
        }
        
        UIDevice.vibrate(isAllowed: viewModel.options.allowVibration)
        
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            if !(viewModel.camera.isRestrictedArchive ?? false) && openOptions.isEventArchive == false {
                let date = Date(timeIntervalSince1970: TimeInterval(timeline.stackView.lastStripeEnd))
                
                let calendar = Calendar.current
                guard let newDate = calendar.date(byAdding: .minute, value: -10, to: date) else { return }
                timelineDidScroll(to: DateFormatter.serverUTC.string(from: newDate))
                timeline.datesCollection.reloadData()
            } else if (viewModel.camera.isRestrictedArchive ?? false) {
                if let date = openOptions.archiveDate {
                    timeline.setDate(date, true)
                    timelineDidScroll(to: DateFormatter.serverUTC.string(from: date))
                } else {
                    if let lastRange = viewModel.camera.archiveRanges?.last?.from {
                        let date = Date(timeIntervalSince1970: TimeInterval( lastRange))
                        timeline.setDate(date, true)
                        timelineDidScroll(to: DateFormatter.serverUTC.string(from: date))
                    } else {
                        viewModel.playerErrorState = (viewModel.camera.isRestrictedArchive ?? false) ? .archiveRestricted : .archiveError
                    }
                }
            }
            if self.openOptions.isEventArchive {
                self.openOptions.isEventArchive = false
            } else {
                dismissMarkCreation()
            }
        }
        
        self.liveArchiveTask = task
        
        //1.0 is the wait or idle time for execution of the function archiveAction
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + (onStart ? 0 : 1), execute: task)
    }
    
    private func configureInactiveTimeline() {
        if viewModel.camera.startFrom?.count != 0 && viewModel.camera.highStream() != nil {
            
            if let lastStart = viewModel.camera.startFrom?.last, let lastDuration = viewModel.camera.durations?.last {
                let endInterval = TimeInterval(lastStart + lastDuration)
                endDate = Date.init(timeIntervalSince1970: endInterval)
            }
        } else {
            self.viewModel.playerErrorState = .archiveError
        }
    }
    
    private func configureTimelineEnd() {
        let nowTimeInterval = Date().timeIntervalSince1970 // проверка, архив закончился давно или сервер не обновил рейнджи
        if viewModel.camera.startFrom?.count != 0 {
            let endInterval = TimeInterval(timeline.stackView.lastStripeEnd)
            let difference = nowTimeInterval - endInterval
            if (viewModel.camera.isRestrictedArchive ?? false) {
                endDate = Date(timeIntervalSince1970: TimeInterval( viewModel.camera.archiveRanges?.last?.rangeEnd() ?? 0))
            } else if difference <= 1200 {
                endDate = Date(timeIntervalSinceNow: -15)
            } else {
                endDate = Date()
            }
        } else {
            endDate = Date()
        }
    }
    
    // MARK: - Get archive from mark
    
    public func getMarkArchive() {
        if let m = openOptions.event, let start = m.from ?? m.createdAt {
            if start < timeline.stackView.firstStartDate && viewModel.camera.highStream() != nil {
                self.delegate?.playerDidReceiveError(message: self.viewModel.translate(.ErrNoArchiveDate))
                removeActivityIndicator()
            } else {
                self.getCameraArchive(of: DateFormatter.serverUTC.string(from: start), completion: { [weak self] in
                    self?.getCameraMarks(date: start) { [weak self] in
                        guard let self else { return }
                        self.timeline.configureMarks(self.viewModel.cameraEvents, hideTimelabel: false)
                        self.timeline.setDate(start, false)
                        self.changeTimelabelCenterConstraint(toPoint: 0)
                        self.timeline.timeLabel.isHidden = false
                        self.timeline.timeLabel.mark = m
                        self.timeline.markLabelVisible = true
                        self.timeline.performHideMark()
                        self.videoLayer.updatePlayerFrame()
                    }
                    self?.timeline.setDate(start, false)
                })
            }
        } else if let archiveDate = openOptions.archiveDate {
            if archiveDate < timeline.stackView.firstStartDate && viewModel.camera.highStream() != nil {
                self.delegate?.playerDidReceiveError(message: self.viewModel.translate(.ErrNoArchiveDate))
                removeActivityIndicator()
            } else {
                self.getCameraArchive(of: DateFormatter.serverUTC.string(from: archiveDate), completion: { [weak self] in
                    self?.getCameraMarks(date: archiveDate) { [weak self] in
                        guard let self else { return }
                        self.timeline.configureMarks(self.viewModel.cameraEvents, hideTimelabel: false)
                        self.timeline.setDate(archiveDate, false)
                        self.changeTimelabelCenterConstraint(toPoint: 0)
                        self.timeline.markLabelVisible = true
                        self.timeline.performHideMark()
                        self.videoLayer.updatePlayerFrame()
                    }
                })
            }
        }
    }
}
 // MARK: - Mark Creation Extensions

extension VMSPlayerController {
    
    private func configureMarkCreationConstraints() {
        
        if !isMarkCreationMode {
            switch UIApplication.shared.statusBarOrientation {
            case .landscapeLeft, .landscapeRight:   // Horizontal when hidden
                createMarkWidthHorizontal.constant = 0
                createMarkLeadingHorizontal.constant = 0
            case .portrait,.portraitUpsideDown:  // Vertical when hidden
                let viewHeight: CGFloat = isSmallIPhone() ? 200 : 240
                createMarkHeightVertical.constant = viewHeight
                createMarkBottomVerticalConstraint.constant = -viewHeight - bottomView.frame.height
                playerScrollBottomConstraint.constant = 0
                createMarkWidthHorizontal.constant = 0
            case .unknown:
                break
            }
        } else if isMarkCreationMode {
            switch UIApplication.shared.statusBarOrientation {
            case .landscapeRight,.landscapeLeft:  // Horizontal when enabled
                createMarkBottomVerticalConstraint.isActive = false
                createMarkTopHorizontal.constant = 0
                createMarkWidthHorizontal.constant = 260
                createMarkTrailingHorizontal.constant = 0
                createMarkLeadingHorizontal.constant = 0
                if UIDevice.current.userInterfaceIdiom == .pad {
                    let center = self.view.center
                    createMarkTopHorizontal.constant = center.y - self.topView.frame.height
                }
            case .portraitUpsideDown,.portrait: // Vertical when enabled
                let viewHeight: CGFloat = isSmallIPhone() ? 200 : 240
                createMarkTopHorizontal.constant = 0
                createMarkHeightVertical.constant = viewHeight
                createMarkBottomVerticalConstraint.isActive = true
                createMarkBottomVerticalConstraint.constant = 16
                createMarkWidthHorizontal.constant = 260
                if UIDevice.current.userInterfaceIdiom == .pad {
                    let center = self.view.center
                    createMarkTopHorizontal.constant = center.y - self.topView.frame.height
                }
                var safeAreaBottom: CGFloat?
                if #available(iOS 11.0, *) {
                    safeAreaBottom = UIApplication.shared.keyWindow?.safeAreaInsets.bottom
                }
                playerScrollBottomConstraint.constant = (viewHeight + 26 + (safeAreaBottom ?? 0)) / (deviceHasNotch ? self.videoLayer.getVideoRatio() : 1)
                
            default:
                break
            }
            self.pausePlayer()
        }
        self.createMarkContainer.setNeedsUpdateConstraints()
    }
    
    func dismissMarkCreation() {
        if (!isPlaying && isMarkCreationMode) {
            showActivityIndicator()
            self.isPlaying = true;
            bottomView.playPauseButton.alpha = 1
        }
        isMarkCreationMode = false
        configureMarkCreationConstraints()
        self.view.layoutSubviews()
        self.markCreationController?.setNameFieldText(viewModel.translate(.MarkNewTitle))
        self.videoLayer.updatePlayerFrame()
        self.view.endEditing(true)
        self.timeline.deleteLongPin()
    }
}

extension VMSPlayerController: CreateMarkDelegate {
    
    func openTimePicker(withDate date: Date) {
        configureTimePicker(currentDate: date)
        self.timePickerAction()
        self.view.endEditing(true)
    }
    
    
    func openPicker(withDate date: Date) {
        self.configureDatePickerDaySelection(currentDate: date)
        self.openDatePicker(nil)
        self.view.endEditing(true)
    }
    
    func createMark(markName: String, from: Date) {
        viewModel.createMark(name: markName, from: from)
    }
    
    func editMark(markId: Int, markName: String, from: Date) {
        viewModel.editMark(markId: markId, name: markName, from: from)
    }
    
    func cancelEdit() {
        self.dismissMarkCreation()
        self.openOptions.showEventEdit = false
        if self.openOptions.popNavigationAfterEventEdit {
            self.backAction(nil)
        } else if self.openOptions.pushEventsListAfterEventEdit {
            openOptions.pushEventsListAfterEventEdit = false
            self.showEventsList()
        } else {
            self.getCameraMarks(date: topView.date ?? Date())
        }
    }
    
    func close() {
        dismissMarkCreation()
        self.getCameraMarks(date: topView.date ?? Date())
    }
    
    func closeKeyboard() {
        self.view.endEditing(true)
    }
}

extension VMSPlayerController: VideoTimelineDelegate {
    
    func getUser() -> VMSUser {
        return viewModel.user
    }
    
    func getIsRestrictedArchive() -> Bool {
        return viewModel.camera.isRestrictedArchive ?? false
    }
    
    func getArchive(mark: VMSEvent) {
        if let from = mark.from {
            getCameraArchive(of: DateFormatter.serverUTC.string(from: from))
        }
    }
    
    func rewindMark(next: Bool) {
        if viewModel.currentEventOption == .none {
            return
        }
        guard let date = topView.date else {
            self.delegate?.playerDidReceiveError(message: next ? viewModel.translate(.NoNewerMarks) : viewModel.translate(.NoOlderMarks))
            return
        }
        viewModel.rewindMark(date: date, direction: next ? VMSRewindDirection.next : VMSRewindDirection.previous, transform: CGFloat(timeline.videoScrollView.transform.a), speed: currentSpeed)
    }
    
    func showMarkCreation(on date: Date) {
        if viewModel.getPlayerStateError() != (nil, nil) {
            return
        }
        isMarkCreationMode = true
        configureMarkCreationConstraints()
        markCreationController?.doneButton.backgroundColor = .buttonNormal
        timeline.showMarksButtons(false)
        self.videoLayer.updatePlayerFrame()
        UIView.animate(withDuration: 0.3) {
            self.videoLayer.needsLayout()
            self.view.layoutIfNeeded()
            self.view.layoutSubviews()
        }
        markCreationController?.date = date
        let dateString = DateFormatter.serverUTC.string(from: date)
        self.getCameraArchive(of: dateString) {
            self.timeline.showLongPin()
            self.timeline.removeMarks()
        }
        self.view.layoutSubviews()
        self.videoLayer.updatePlayerFrame()
        self.setVideoLayerScrollToCenter()
    }
    
    func setVideoLayerScrollToCenter() {
        let centerOffsetX = (videoLayerScroll.contentSize.width - videoLayerScroll.frame.size.width) / 2
        let centerOffsetY = (videoLayerScroll.contentSize.height - videoLayerScroll.frame.size.height) / 2
        let centerPoint = CGPoint(x: centerOffsetX, y: centerOffsetY)
        videoLayerScroll.setContentOffset(centerPoint, animated: true)
    }
    
    func updateMarkCreation(withDate date: Date) {
        if isMarkCreationMode {
            markCreationController?.date = date
            if openOptions.showEventEdit, let mark = self.timeline.timeLabel.mark {
                mark.from = date
                self.timeline.timeLabel.mark = mark
            }
        } else {
            self.timeline.timeLabel.mark = nil
        }
    }
    
    func changeTimelabelCenterConstraint(toPoint point: CGFloat) {
        if point == 0 {
            self.timeLabelCenterXConstraint.constant = 0
        } else {
            var finalPoint = CGFloat()
            let halfTimelabelWidth = self.timeline.timeLabel.frame.size.width / 2
            let center = self.view.center
            if point < center.x { // марка слева от центра
                let pointToMove = center.x - point
                let startOfScreen: CGFloat = 0
                if center.x - pointToMove < startOfScreen + halfTimelabelWidth {
                    finalPoint = -(center.x - halfTimelabelWidth)
                } else {
                    finalPoint = -pointToMove
                }
            } else { // марка справа от центра
                let pointToMove = point - center.x
                let endOfScreen = self.view.frame.maxX
                if center.x + pointToMove > endOfScreen - halfTimelabelWidth {
                    finalPoint = center.x - halfTimelabelWidth
                } else {
                    finalPoint = pointToMove
                }
            }
            
            self.timeLabelCenterXConstraint.constant = finalPoint
            UIView.animate(withDuration: 0.3, animations:{
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func showTimeline() {
        if !isLive && !isControlsHiden  {
            isArchiveDisabled = false
            self.timeline.isHidden = false
            self.bottomView.isHidden = false
        }
    }
    
    func hideTimeline() {
        isArchiveDisabled = true
        self.timeline.isHidden = true
        self.bottomView.isHidden = true
    }
    
    func reloadStripes() {
        timeline.reloadArchiveStripes()
    }
    
    func timelineDidScroll(to dateString: String) {
        
        self.timelineDidScrollTask?.cancel()
        timeUpdaterTimer?.invalidate()
        isPlaying = false
        
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if viewModel.camera.startFrom?.count != 0 {
                if let firstStart = viewModel.camera.startFrom?[0] {
                    let lastEndPoint = timeline.stackView.lastStripeEnd
                    if let date = DateFormatter.serverUTC.date(from: dateString) {
                        let newDateTimeInterval = date.timeIntervalSince1970
                        
                        if newDateTimeInterval < TimeInterval(firstStart) {
                            let startDate = Date(timeIntervalSince1970: TimeInterval(firstStart))
                            let startDateString = DateFormatter.serverUTC.string(from: startDate)
                            timeUpdaterTimer?.invalidate()
                            getCameraArchive(of: startDateString)
                            return
                        } else if newDateTimeInterval > TimeInterval(lastEndPoint) {
                            let endDate = Date(timeIntervalSince1970: TimeInterval(lastEndPoint - 15)) // немного отнимаем, чтобы сервер не присылал нам отрезки из лайва, если архив закончился час - два назад.
                            let endDateString = DateFormatter.serverUTC.string(from: endDate)
                            timeUpdaterTimer?.invalidate()
                            
                            getCameraArchive(of: endDateString)
                            return
                        }
                    }
                }
            }
            timeUpdaterTimer?.invalidate()
            getCameraArchive(of: dateString)
        }
        
        self.timelineDidScrollTask = task
          
          //1.0 is the wait or idle time for execution of the function timelineDidScroll
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: task)
    }
}

extension VMSPlayerController: UIScrollViewDelegate {
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return videoLayer
    }
}

extension VMSPlayerController: UIPickerViewDataSource, UIPickerViewDelegate {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0:
            return 25
        case 1,2:
            return 60
        default:
            return 0
        }
    }
    
    public func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return pickerView.frame.size.width / 3
    }
    
    public func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        var stringRow = String(row)
        if row <= 9 {
            stringRow = "0\(row)"
        }
        let atrString = NSAttributedString(string: stringRow, attributes: [NSAttributedString.Key.foregroundColor : UIColor.white])
        return atrString
    }
    
}

extension VMSPlayerController: VideoPlayerDelegate {
    
    func playerStartedToPlay() {
        viewModel.playerErrorState = .normal
        if self.activityIndicator.isAnimating {
            self.removeActivityIndicator()
        }
        if !isMarkCreationMode {
            self.setTimeUpdaterTimer()
        } else if isMarkCreationMode || openOptions.showEventEdit {
            self.pausePlayer()
            self.setVideoLayerScrollToCenter()
        }
    }
    
    func archivePlayDidFail() -> Bool {
        guard !isLive, let cameraLastArchiveRange = viewModel.camera.archiveRanges?.last?.rangeEnd() else {
            return false
        }
        if let markTimeline = openOptions.event?.from?.timeIntervalSince1970 {
            return markTimeline > cameraLastArchiveRange
        }
        return timeline.stackView.lastStripeEnd > cameraLastArchiveRange
    }
    
    func playerDidFail(message: String?) {
        if archivePlayDidFail() {
//            timeline.setToEnd(needUpdate: false)
            enableRewindButtons()
            viewModel.playerErrorState = .archiveOutOfRange
        } else if let message = message, message.contains("HTTP 204") {
            viewModel.playerErrorState = .archiveOutOfRange           
        } else {
            self.delegate?.playerDidReceiveError(message: viewModel.translate(.ErrCommonShort))
        }
        if isMarkCreationMode {
            dismissMarkCreation()
        }
        self.timeUpdaterTimer?.invalidate()
        isPlaying = false
        removeActivityIndicator()
        self.videoLayer.endPlayer()
        self.soundButton.isHidden = true
        self.soundBottomButton.isHidden = true
//        self.videoLayer.setup(type: viewModel.getPlayerType(), withDelegate: self)
    }
    
    func playerPerformanceFail() {
        self.delegate?.playerDidReceiveError(message: viewModel.translate(.ErrDevicePerformance))
        if isMarkCreationMode {
            dismissMarkCreation()
        }
        self.timeUpdaterTimer?.invalidate()
        isPlaying = false
        removeActivityIndicator()
        self.videoLayer.endPlayer()
        self.soundButton.isHidden = true
        self.soundBottomButton.isHidden = true
    }
    
    func playerNeedToRestart() {
        if isLive && isRtsp {
            getCameraStream()
        }
    }
    
    func playerItemDidReadyToPlay() {
        self.removeActivityIndicator()
//        if !isMarkCreationMode {
//             self.isPlaying = true
//        }
        self.setTimeUpdaterTimer()
        if isMarkCreationMode || openOptions.showEventEdit {
            self.pausePlayer()
            self.setVideoLayerScrollToCenter()
        }
    }
    
    func playerHasScreenshot(screenshot: UIImage?) {
        guard
            let dateString = topView.dateLabel.text,
            let date = DateFormatter.yearMonthDay.date(from: dateString) else {
                self.delegate?.playerDidReceiveError(message: viewModel.translate(.ErrCommonShort))
            return
        }
        guard let image = screenshot else {
            self.delegate?.playerDidReceiveError(message: viewModel.translate(.ErrCommonShort))
            return
        }
        self.delegate?.screenshotCreated(image: image, cameraName: viewModel.camera.name ?? "", date: date)
    }
    
    func playerHasSound(hasSound: Bool) {
        if self.currentSpeed == 1 &&  !viewModel.options.onlyScreenshotMode {
            if self.isLive {
                self.soundButton.isHidden = !hasSound
            }
            self.soundBottomButton.isHidden = !hasSound
            self.soundOn = self.viewModel.isSoundOn
            if (self.viewModel.isSoundOn && hasSound) {
                self.videoLayer.setVolume(hasSound ? 1 : 0)
            }
        } else {
            self.soundButton.isHidden = true
            self.soundBottomButton.isHidden = true
            self.soundOn = false
            if (self.viewModel.isSoundOn && self.soundOn) {
                self.videoLayer.setVolume(self.soundOn ? 1 : 0)
            }
        }
    }
}

extension VMSPlayerController: VideoFooterViewDelegate {
    
    internal func rewindPlayer(_ component: Calendar.Component, value: Int) {
        let calendar = Calendar.current
        if isMarkCreationMode {
            guard let currentDate = markCreationController?.date,
                let newDate = calendar.date(byAdding: component, value: value, to: currentDate, wrappingComponents: false),
                  let startDate = viewModel.camera.startAt else {
                    return
            }
            let endTimeinterval = TimeInterval(timeline.stackView.lastStripeEnd)
            let endDate = Date(timeIntervalSince1970: endTimeinterval)
            let date = min(max(newDate, startDate), endDate)
            let newDateString = DateFormatter.serverUTC.string(from: date)
            self.timeline.showTimeLabel(message: "\(value) " + viewModel.getTimeComponentTranslation(component: component))
            getCameraArchive(of: newDateString)
            if date == startDate {
                timeline.setToBeginning()
            } else if date == endDate {
                timeline.setToEnd()
            } else {
                timeline.setDate(date, true)
            }
            self.updateMarkCreation(withDate: date)
        } else {
            guard let currentDate = topView.date,
                  let newDate = calendar.date(byAdding: component, value: value, to: currentDate, wrappingComponents: false),
                  let startDate = viewModel.camera.startAt else {
                return
            }
            let endTimeinterval = TimeInterval(timeline.stackView.lastStripeEnd)
            let endDate = Date(timeIntervalSince1970: endTimeinterval)
            let date = min(max(newDate, startDate), endDate)
            let newDateString = DateFormatter.serverUTC.string(from: date)
            self.timeline.showTimeLabel(message: "\(value) " + viewModel.getTimeComponentTranslation(component: component))
            getCameraArchive(of: newDateString)
            if date == startDate {
                timeline.setToBeginning()
            } else if date == endDate {
                timeline.setToEnd()
            } else {
                timeline.setDate(date, true)
            }
        }
        
        UIDevice.vibrate(isAllowed: viewModel.options.allowVibration)
    }
}

extension VMSPlayerController: VMSPlayerViewModelDelegate {
    
    func getAvailableMarkTypes() -> [VMSEventType] {
        return viewModel.options.markTypes
    }
    
    func playerTypeChanged() {
        if isLive {
            liveAction(onStart: false)
        } else {
            archiveAction(onStart: false)
        }
    }
    
    func qualityChanged() {
        if viewModel.hasEventsPermissions() {
            liveOptionsButton.setImage(UIImage(named: "options", in: Bundle(for: VMSPlayerController.self), with: nil), for: .normal)
        } else {
            switch viewModel.currentQuality {
            case .high:
                liveOptionsButton.setImage(UIImage(named: "hd", in: Bundle(for: VMSPlayerController.self), with: nil), for: .normal)
            case .low:
                liveOptionsButton.setImage(UIImage(named: "sd", in: Bundle(for: VMSPlayerController.self), with: nil), for: .normal)
            }
        }
    }
    
    func userReloaded() {
        reloadPermissions()
    }
    
    func liveStreamDidLoaded(url: String) {
        self.delegate?.playerDidReceiveInfo(message: "VMSPlayerController received live URL:\n\(url)")
        guard let url = URL(string: url) else {
            self.delegate?.playerDidReceiveError(message: viewModel.translate(.StreamNotAvailable))
            self.removeActivityIndicator()
            return
        }
        self.currentSpeed = 1
        self.videoLayer.playUrl(url)
        self.videoLayer.setVolume(self.soundOn ? 1 : 0)
        self.topView.date = Date()
        self.setTimeUpdaterTimer()
    }
    
    func liveStreamDidLoadedWithError(_ error: String) {
        self.removeActivityIndicator()
        self.delegate?.playerDidReceiveError(message: error)
    }
    
    func archiveStreamDidLoadedWithError(_ error: String) {
        enableButtons(true)
        removeActivityIndicator()
        bottomView.screenshotButton.alpha = 0
        if viewModel.camera.isRestrictedArchive ?? false {
            isPlaying = false
            viewModel.playerErrorState = (viewModel.camera.isRestrictedArchive ?? false) ? .archiveRestricted : .archiveError
        } else if error == "422" {
            // We receive 422 if user goes to the beginning of archive but we no longer have it
            reloadCameraBeginning()
        } else {
            self.delegate?.playerDidReceiveError(message: error)
            hideTimeline()
        }
    }
    
    func markCreated(from: Date) {
        dismissMarkCreation()
        markCreationController?.setNameFieldText(viewModel.translate(.MarkNewTitle))
        getCameraMarks(date: from)
        delegate?.logPlayerEvent(event: "EVENT_CREATED")
    }
    
    func markHandlerError(_ error: String) {
        self.delegate?.playerDidReceiveError(message: error)
    }
    
    func markEdited(id: Int, name: String, from: Date) {
        self.dismissMarkCreation()
        self.openOptions.showEventEdit = false
        delegate?.logPlayerEvent(event: "EVENT_EDITED")
        if self.openOptions.popNavigationAfterEventEdit {
            self.backAction(nil)
        } else if self.openOptions.pushEventsListAfterEventEdit {
            openOptions.pushEventsListAfterEventEdit = false
            self.showEventsList()
        } else {
            self.getCameraMarks(date: from)
            let newBookmark = VMSEvent(id: id, from: from, title: name)
            self.timeline.timeLabel.mark = newBookmark
        }
    }
    
    func markRewinded(mark: VMSEvent?, direction: VMSRewindDirection) {
        if let markCreatedDate = mark?.from {
            if markCreatedDate < self.timeline.stackView.firstStartDate {
                self.delegate?.playerDidReceiveError(message: viewModel.translate(.OlderMarksNotAvailable))
                UIDevice.warningVibration(isAllowed: viewModel.options.allowVibration)
                return
            }
            pausePlayer()
            let dateString = DateFormatter.serverUTC.string(from: markCreatedDate)
            self.timeline.setDate(markCreatedDate, true)
            self.getCameraArchive(of: dateString) {
                self.timeline.markLabelVisible = true
                self.timeline.timeLabel.mark = mark
                self.changeTimelabelCenterConstraint(toPoint: 0)
                self.timeline.timeLabel.isHidden = false
                self.timeline.performHideMark()
            }
        } else {
            self.delegate?.playerDidReceiveError(message: direction == .next ? viewModel.translate(.NoNewerMarks) : viewModel.translate(.NoOlderMarks))
        }
    }
    
    func markOptionChanged() {
        self.timeline.setAllowShowMarks(allow: viewModel.currentEventOption != .none)
    }
    
    func playerErrorStateChanged() {
        noDataView.configureView(info: viewModel.getPlayerStateError())
    }
}

extension VMSPlayerController: DownloadArchiveControllerDelegate {
    
    func controllerError(message: String) {
        delegate?.playerDidReceiveError(message: message)
    }
}
