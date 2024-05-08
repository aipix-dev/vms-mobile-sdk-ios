
import UIKit

protocol ChooseTimeDelegate: AnyObject {
    func timeSelected(selectedTime: Date)
    func getTranslations() -> VMSPlayerTranslations
}

protocol DownloadCalendarDelegate: AnyObject {
    func selectedDate(date: Date?, type: DownloadCalendarController.DownloadCalendarType)
}

class DownloadCalendarController: UIViewController {
    
    enum DownloadCalendarType {
        case start
        case end
    }

    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var handle: UIView!
    @IBOutlet weak var viewHeight: NSLayoutConstraint!
    @IBOutlet weak var timeBackView: UIView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var previousMonthButton: UIButton!
    @IBOutlet weak var nextMonthButton: UIButton!
    @IBOutlet weak var dayOfWeekStackView: UIStackView!
    
    @IBOutlet weak var timeNameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var timeView: UIView!
    @IBOutlet weak var timeButton: UIButton!
    
    @IBOutlet weak var readyButton: UIButton!
    
    weak var delegate: DownloadCalendarDelegate?
    
    public var type: DownloadCalendarType = .start
    
    public var selectedDate: Date!
    
    public var time = Date()
    
    public var enabledRanges = [VMSArchiveRanges]()
    
    public var translations: VMSPlayerTranslations!
    public var locale: Locale!

    var startPosition: CGPoint!
    var translation: CGPoint!
    var originalHeight: CGFloat = 0
    var difference: CGFloat!
    
    private var height = CGFloat()
    private var maxHeight = CGFloat()
        
    private let weekdayOffset: Int = 1
    private var baseDate: Date! {
        didSet {
            days = generateDaysInMonth(for: baseDate)
            collectionView.reloadData()
            monthLabel.text = getMonthName(date: baseDate).capitalized + " " + calendarYear.string(from: baseDate)
        }
    }
    private let calendar = Calendar.current
    private var currentSender: UIButton?
    
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        return dateFormatter
    }()
    
    private lazy var yearDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ru_RU")
        dateFormatter.dateFormat = "y"
        return dateFormatter
    }()
    
    private lazy var calendarYear: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = "yyyy"
        return dateFormatter
    }()
    
    private lazy var hourMinuteSecond: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        return dateFormatter
    }()
    
    private lazy var days = generateDaysInMonth(for: baseDate)
    public var selectedDateChanged: ((Date?) -> Void)?
    
    private var numberOfWeeksInBaseDate: Int {
        calendar.range(of: .weekOfMonth, in: .month, for: baseDate)?.count ?? 0
    }
    
    public var completionHandler: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
        
        baseDate = selectedDate
        
        timeLabel.text = hourMinuteSecond.string(from: time)
        timeNameLabel.text = type == .start ? translations.translate(.ArchiveDownloadStartTime) : translations.translate(.ArchiveDownloadEndTime)
        readyButton.setTitle(translations.translate(.CheckDone), for: .normal)
        
        initDaysStackView()
        
        height = 485
        maxHeight = height + (isSmallIPhone() ? 50 : 100)
        viewHeight.constant = height
        
        view.backgroundColor = .clear
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(viewDidDragged(_:)))
        bottomView.addGestureRecognizer(panRecognizer)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previousMonthButton.layer.cornerRadius = previousMonthButton.bounds.width / 2
        nextMonthButton.layer.cornerRadius = nextMonthButton.bounds.width / 2
    }
    
    private func configure() {
        let cornerRad: CGFloat = 6
        
        timeView.layer.cornerRadius = cornerRad
        
        bottomView.layer.cornerRadius = 16
        
        previousMonthButton.backgroundColor = UIColor.clear
        previousMonthButton.layer.borderWidth = 1
        previousMonthButton.layer.borderColor = UIColor.init(hex: 0xEFF2F5).cgColor
        nextMonthButton.backgroundColor = UIColor.clear
        nextMonthButton.layer.borderWidth = 1
        nextMonthButton.layer.borderColor = UIColor.init(hex: 0xEFF2F5).cgColor
        handle.layer.cornerRadius = 2

        if isSmallIPhone() {
            height = 560
            maxHeight = height + 50
        } else {
            height = 560
            maxHeight = height + 100
        }
        viewHeight.constant = height
    }
    
    @objc private func handleSwipe(_ gestureRecognizer: UISwipeGestureRecognizer) {
        completeAndDismiss()
    }
    
    private func completeAndDismiss() {
        if let vc = presentedViewController as? ArchiveTimeController {
            vc.completeAndDismiss()
            timeBackView.isHidden = true
            return
        }
        self.dismiss(animated: true, completion: nil)
        completionHandler?()
    }
    
    @objc private func viewDidDragged(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            startPosition = sender.location(in: bottomView)
        }
        
        if sender.state == .began || sender.state == .changed {
            translation = sender.translation(in: self.bottomView)
            sender.setTranslation(CGPoint(x: 0.0, y: 0.0), in: self.bottomView)
            let endPosition = sender.location(in: bottomView)
            difference = endPosition.y - startPosition.y
            var newFrame = bottomView.frame
            newFrame.size.height = bottomView.frame.size.height - difference
            if newFrame.size.height >= maxHeight {
                viewHeight.constant = maxHeight
                return
            }
            if newFrame.size.height <= height - 80 {
                completeAndDismiss()
                return
            }
            viewHeight.constant = newFrame.size.height
        }
        
        if sender.state == .ended || sender.state == .cancelled {
            
            if self.viewHeight.constant != height {
                self.viewHeight.constant = height
                self.view.setNeedsLayout()
                UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: {
                    self.view.layoutIfNeeded()
                }, completion: nil)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let touch = touches.first
        guard let location = touch?.location(in: self.view) else { return }
        if !bottomView.frame.contains(location) {
            completeAndDismiss()
        }
    }
    
    private func initDaysStackView() {
        for dayNumber in 1...7 {
            let dayLabel = UILabel()
            dayLabel.font = .systemFont(ofSize: 12, weight: .medium)
            dayLabel.textColor = .mainGrey
            dayLabel.textAlignment = .center
            dayLabel.text = dayOfWeekLetter(for: dayNumber)
            
            dayLabel.isAccessibilityElement = false
            dayOfWeekStackView.addArrangedSubview(dayLabel)
        }
    }
    
    private func dayOfWeekLetter(for dayNumber: Int) -> String {
        switch dayNumber {
        case 1:
            return translations.translate(.Monday)
        case 2:
            return translations.translate(.Tuesday)
        case 3:
            return translations.translate(.Wednesday)
        case 4:
            return translations.translate(.Thursday)
        case 5:
            return translations.translate(.Friday)
        case 6:
            return translations.translate(.Saturday)
        case 7:
            return translations.translate(.Sunday)
        default:
            return ""
        }
    }
    
    func getMonthName(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = self.locale
        let comps = Calendar.current.dateComponents([.month], from: date)
        return dateFormatter.standaloneMonthSymbols[(comps.month ?? 1) - 1]
    }
    
    // MARK: - Actions
    
    @IBAction func readyAction(_ sender: Any) {
//        if startTime > endTime {
//            self.showSnackBar(Translations.Errors.ArchiveFormatError.localized)
//            return
//        }
//
//        guard startTime < endTime, Int(endTime.timeIntervalSince1970 - startTime.timeIntervalSince1970) <= 10 * 60 else {
//            self.showSnackBar(Translations.Errors.ArchivePeriodError.localized)
//            return
//        }
        delegate?.selectedDate(date: time, type: type)
        completeAndDismiss()
    }
    
    @IBAction func nextMonthAction(_ sender: Any) {
        self.baseDate = self.calendar.date(
            byAdding: .month,
            value: 1,
            to: self.baseDate
        ) ?? self.baseDate
    }
    
    @IBAction func previousMonthAction(_ sender: Any) {
        self.baseDate = self.calendar.date(
            byAdding: .month,
            value: -1,
            to: self.baseDate
        ) ?? self.baseDate
    }
    
    @IBAction func chooseTimeAction(_ sender: UIButton?) {
        currentSender = sender
        performSegue(withIdentifier: "ShowTime", sender: sender)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        if identifier == "ShowTime",
           let dest = segue.destination as? ArchiveTimeController {
            dest.delegate = self
            timeBackView.isHidden = false
            dest.date = time
            dest.completionHandler = { [weak self] in
                self?.timeBackView.isHidden = true
                self?.view.alpha = 1.0
                self?.navigationController?.view.alpha = 1
            }
        }
    }
}

// MARK: - Day Generation
private extension DownloadCalendarController {
    
    func monthMetadata(for baseDate: Date) throws -> MonthMetadata {
        guard
            let numberOfDaysInMonth = calendar.range(
                of: .day,
                in: .month,
                for: baseDate)?.count,
            let firstDayOfMonth = calendar.date(
                from: calendar.dateComponents([.year, .month], from: baseDate))
        else {
            throw CalendarDataError.metadataGeneration
        }
        
        let firstDayWeekday: Int = {
            var weekday = calendar.component(.weekday, from: firstDayOfMonth) - weekdayOffset
            guard weekday != 0 else { weekday = 7; return weekday }
            return weekday
        }()
        
        return MonthMetadata(
            numberOfDays: numberOfDaysInMonth,
            firstDay: firstDayOfMonth,
            firstDayWeekday: firstDayWeekday)
    }
    
    func generateDaysInMonth(for baseDate: Date) -> [ArchiveDay] {
        guard let metadata = try? monthMetadata(for: baseDate) else {
            preconditionFailure("An error occurred when generating the metadata for \(baseDate)")
        }
        
        let numberOfDaysInMonth = metadata.numberOfDays
        let offsetInInitialRow = metadata.firstDayWeekday
        let firstDayOfMonth = metadata.firstDay
        
        var days: [ArchiveDay] = (1..<(numberOfDaysInMonth + offsetInInitialRow))
            .map { day in
                let isWithinDisplayedMonth = day >= offsetInInitialRow
                let dayOffset =
                isWithinDisplayedMonth ?
                day - offsetInInitialRow :
                -(offsetInInitialRow - day)
                
                return generateDay(
                    offsetBy: dayOffset,
                    for: firstDayOfMonth,
                    isWithinDisplayedMonth: isWithinDisplayedMonth)
            }
        
        days += generateStartOfNextMonth(using: firstDayOfMonth)
        
        return days
    }
    
    func generateDay(
        offsetBy dayOffset: Int,
        for baseDate: Date,
        isWithinDisplayedMonth: Bool
    ) -> ArchiveDay {
        let date = calendar.date(
            byAdding: .day,
            value: dayOffset,
            to: baseDate)
        ?? baseDate
        var selected = false
        var isToday = false
        var moreThanToday = false
        var lessThenArchiveStart = false
        if date > Date() {
            moreThanToday = true
        }
        let archiveStart = Date(timeIntervalSince1970: TimeInterval(enabledRanges.first?.from ?? 0))
        if date < archiveStart && !calendar.isDate(date, inSameDayAs: archiveStart) {
            lessThenArchiveStart = true
        }
        if calendar.isDate(date, inSameDayAs: Date()) {
            isToday = true
        }
        if calendar.isDate(date, inSameDayAs: time) {
            selected = true
        }
        
        return ArchiveDay(
            date: date,
            number: dateFormatter.string(from: date),
            isSelected: selected,
            isWithinDisplayedMonth: isWithinDisplayedMonth,
            isToday: isToday,
            enabled: !lessThenArchiveStart && !moreThanToday
        )
    }
    
    func generateStartOfNextMonth(
        using firstDayOfDisplayedMonth: Date
    ) -> [ArchiveDay] {
        guard
            let lastDayInMonth = calendar.date(
                byAdding: DateComponents(month: 1, day: -1),
                to: firstDayOfDisplayedMonth)
        else {
            return []
        }

        let additionalDays = 7 - calendar.component(.weekday, from: lastDayInMonth) + weekdayOffset
        guard additionalDays > 0 else { return [] }
        let days: [ArchiveDay] = (1...additionalDays).map {
                    generateDay(
                    offsetBy: $0,
                    for: lastDayInMonth,
                    isWithinDisplayedMonth: false)
            }
        return days
    }
    
    enum CalendarDataError: Error {
        case metadataGeneration
    }
}

// MARK: - UICollectionViewDataSource
extension DownloadCalendarController: UICollectionViewDataSource {
    
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int {
        days.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let day = days[indexPath.row]
            
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ArchiveCalendarDayCell.reuseIdentifier,
            for: indexPath) as! ArchiveCalendarDayCell
            
        cell.day = day
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension DownloadCalendarController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let day = days[indexPath.row]
        if !day.enabled {
            return
        }
        selectedDate = day.date
        
        let comps = Calendar.current.dateComponents([.hour, .minute, .second], from: time)
        time = Calendar.current.date(bySettingHour: comps.hour ?? 0, minute: comps.minute ?? 0, second: comps.second ?? 0, of: selectedDate) ?? Date().tenMinAfter()
        
//        if (endComps.minute ?? 0) < 10 && (endComps.hour ?? 0) < 1  {
//            // less than 10min
//            if calendar.isDate(endTime, inSameDayAs: startTime) {
//                endTime = calendar.date(byAdding: .day, value: 1, to: endTime) ?? endTime
//            }
//        }
        
        days = generateDaysInMonth(for: baseDate)
        collectionView.reloadData()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = Int(collectionView.frame.width / 7)
        let height = Int(collectionView.frame.height) / numberOfWeeksInBaseDate
        return CGSize(width: width, height: height)
    }
}

extension DownloadCalendarController: ChooseTimeDelegate {
    
    func timeSelected(selectedTime: Date) {
        let comps = calendar.dateComponents([.hour, .minute, .second], from: selectedTime)
        
        guard let newDate = calendar.date(bySettingHour: comps.hour ?? 0, minute: comps.minute ?? 0, second: comps.second ?? 0, of: selectedDate) else { return }
        time = newDate
        timeLabel.text = hourMinuteSecond.string(from: time)
        timeLabel.textColor = UIColor.init(hex: 0x5A6072)
        
        
//        let endComps = calendar.dateComponents([.minute, .hour], from: endTime)
//        if (endComps.minute ?? 0 < 10) && (endComps.hour ?? 0 < 1)  {
//            // less than 10min
//            if calendar.isDate(endTime, inSameDayAs: startTime) {
//                endTime = calendar.date(byAdding: .day, value: 1, to: endTime) ?? endTime
//            }
//        } else if !calendar.isDate(endTime, inSameDayAs: startTime) {
//            endTime = calendar.date(byAdding: .day, value: -1, to: endTime) ?? endTime
//        }
//        let archiveEnd = Date(timeIntervalSince1970: TimeInterval(enabledRanges.last?.rangeEnd() ?? 0))
//        if endTime > archiveEnd {
//            endTime = archiveEnd
//        }
        
        days = generateDaysInMonth(for: baseDate)
        collectionView.reloadData()
    }
    
    func getTranslations() -> VMSPlayerTranslations {
        return translations
    }
}

