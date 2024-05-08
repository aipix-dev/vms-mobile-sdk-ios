

import UIKit
import Photos

protocol DownloadArchiveControllerDelegate: AnyObject {
    func controllerError(message: String)
}

class DownloadArchiveController: UIViewController {

    @IBOutlet weak var handle: UIView!
    @IBOutlet weak var viewHeight: NSLayoutConstraint!
    @IBOutlet weak var startPeriodButton: UIButton!
    @IBOutlet weak var endPeriodButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var downloadTitle: UILabel!
    @IBOutlet weak var archiveStartLabel: UILabel!
    @IBOutlet weak var archiveEndLabel: UILabel!
    @IBOutlet weak var downloadDescription: UILabel!
    
    @IBOutlet weak var bottomView: UIView! {
        didSet {
            bottomView.layer.cornerRadius = 16
        }
    }

    var startPosition: CGPoint!
    var translation: CGPoint!
    var originalHeight: CGFloat = 0
    var difference: CGFloat!
    
    private var height = CGFloat()
    private var maxHeight = CGFloat()
    
    public var startDate: Date?
    private var endDate: Date?
    
    private var camera: VMSCamera!
    
    private lazy var dayMonthYearTime: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy HH:mm:ss"
        dateFormatter.locale = self.locale
        return dateFormatter
    }()
    
    private var translations: VMSPlayerTranslations!
    private var locale: Locale!
    private var api: PlayerApi?
    
    public weak var delegate: DownloadArchiveControllerDelegate?
    
    static func initialization(camera: VMSCamera, startDate: Date?, locale: Locale, translations: VMSPlayerTranslations, api: PlayerApi) -> DownloadArchiveController {
        let storyboard = UIStoryboard.init(name: "VMSPlayer", bundle: Bundle(for: self))
        let controller = storyboard.instantiateViewController(withIdentifier: "DownloadArchiveController") as! DownloadArchiveController
        controller.startDate = startDate
        controller.camera = camera
        controller.translations = translations
        controller.locale = locale
        controller.api = api
        return controller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        height = 370
        
        if isSmallIPhone() {
            viewHeight.constant = height > 316 ? 316 : height
            maxHeight = viewHeight.constant + 50
        } else {
            viewHeight.constant = height
            maxHeight = viewHeight.constant + 100
        }
        
        view.layoutSubviews()
        
        view.backgroundColor = .clear
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(viewDidDragged(_:)))
        bottomView.addGestureRecognizer(panRecognizer)
        
        
        originalHeight = height
        
        setUI()
        checkDates()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        downloadTitle.text = translations.translate(.DownloadArchiveTitle)
        downloadDescription.text = translations.translate(.DownloadArchiveDescription)
        archiveStartLabel.text = translations.translate(.ArchiveDownloadStartTime)
        archiveEndLabel.text = translations.translate(.ArchiveDownloadEndTime)
    }
    
    private func setUI() {
        startPeriodButton.layer.cornerRadius = 6
        endPeriodButton.layer.cornerRadius = 6
        
        if #available(iOS 15.0, *) {
            var configuration = UIButton.Configuration.plain()
            configuration.title = translations.translate(.DownloadArchive)
            configuration.image = UIImage(named: "download_archive", in: Bundle(for: VMSPlayerController.self), with: nil)?.withRenderingMode(.alwaysTemplate)
            configuration.imagePadding = 10
            downloadButton.configuration = configuration
            downloadButton.tintColor = .main
        } else {
            // Fallback on earlier versions
            let image = UIImage(named: "download_archive", in: Bundle(for: VMSPlayerController.self), with: nil)
            downloadButton.setImage(image?.withRenderingMode(.alwaysTemplate), for: .normal)
            downloadButton.imageView?.tintColor = .main
            downloadButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        }
        
        downloadButton.setTitle(translations.translate(.DownloadArchive), for: .normal)
        
        startPeriodButton.setTitle(translations.translate(.ChooseTime), for: .normal)
        endPeriodButton.setTitle(translations.translate(.ChooseTime), for: .normal)
        startPeriodButton.titleLabel?.textColor = .main
        endPeriodButton.titleLabel?.textColor = .main
    }
    
    private func checkDates() {
        guard var start = startDate else { return }
        endDate = start.tenMinAfter()
        let archiveEnd = Date(timeIntervalSince1970: TimeInterval(camera.archiveRanges?.last?.rangeEnd() ?? 0))
        if let end = endDate,
            end > archiveEnd {
            endDate = archiveEnd
        }
        if let end = endDate,
           start > end {
            startDate = end.tenMinBefore()
            start = end.tenMinBefore()
        }
        let formatter = dayMonthYearTime
        
        startPeriodButton.setTitle(formatter.string(from: start), for: .normal)
        endPeriodButton.setTitle(formatter.string(from: endDate ?? start), for: .normal)
    }
    
    private func chooseTimeAction(type: DownloadCalendarController.DownloadCalendarType) {
        guard let calendarController = self.storyboard?.instantiateViewController(withIdentifier: "DownloadCalendarController") as? DownloadCalendarController else { return }
        calendarController.modalPresentationStyle = .overFullScreen
        calendarController.modalTransitionStyle = .coverVertical
        calendarController.delegate = self
        calendarController.translations = self.translations
        calendarController.locale = self.locale
        calendarController.enabledRanges = camera.archiveRanges ?? []
        calendarController.selectedDate = (type == .start ? startDate : endDate) ?? Date()
        calendarController.type = type
        calendarController.time = type == .start ? startDate ?? Date() : endDate ?? Date().tenMinAfter()
        self.view.alpha = 0.7
        navigationController?.view.alpha = 0.7
        self.present(calendarController, animated: true, completion: nil)
        calendarController.completionHandler = { [weak self] in
            self?.view.alpha = 1
            self?.navigationController?.view.alpha = 1
        }
    }
    
    private func validateTimeInterval() -> Bool {
        guard let start = startDate, let end = endDate else {
            delegate?.controllerError(message: translations.translate(.ChooseTime))
            return false
        }
        if start > end {
            delegate?.controllerError(message: translations.translate(.ArchiveFormatError))
            return false
        }

        guard start < end, Int(end.timeIntervalSince1970 - start.timeIntervalSince1970) <= 10 * 60 else {
            delegate?.controllerError(message: translations.translate(.ArchivePeriodError))
            return false
        }
        return true
    }
    
    private func downloadArchive() {
        guard let start = self.startDate, let end = self.endDate else {
            return
        }
        self.downloadButton.isEnabled = false
        
        api?.getArchiveLink(cameraId: camera.id, from: start, to: end, completion: { [weak self] response in
            guard let self = self else { return }
            self.downloadButton.isEnabled = true
            switch response {
            case .success(_):
                self.completeAndDismiss()
            case .failure(let error):
                self.delegate?.controllerError(message: error.message ?? self.translations.translate(.ErrCommonShort))
            }
        })
    }
    
    // MARK: - Interaction
    
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
            if newFrame.size.height <= height - 60 {
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
    
    @objc private func handleSwipe(_ gestureRecognizer: UISwipeGestureRecognizer) {
        completeAndDismiss()
    }
    
    private func completeAndDismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Actions
    
    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: view)
        if point.y < bottomView.frame.origin.y {
            completeAndDismiss()
        }
        
    }
    
    @IBAction func startTimeAtion(_ sender: Any?) {
        chooseTimeAction(type: .start)
    }
    
    @IBAction func endTimeAction(_ sender: Any?) {
        chooseTimeAction(type: .end)
    }
    
    @IBAction func downloadAction() {
        if !validateTimeInterval() {
            return
        }
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
                if status == .authorized || status == .limited {
                    DispatchQueue.main.async {
                        self?.downloadArchive()
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.completeAndDismiss()
                    }
                }
            }
        } else {
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                if status == .authorized {
                    DispatchQueue.main.async {
                        self?.downloadArchive()
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.completeAndDismiss()
                    }
                }
            }
        }
    }
}

extension DownloadArchiveController: DownloadCalendarDelegate {
    
    func selectedDate(date: Date?, type: DownloadCalendarController.DownloadCalendarType) {
        guard let date = date else { return }
        let formatter = dayMonthYearTime
        
        if type == .start {
            self.startDate = date
            startPeriodButton.setTitle(formatter.string(from: date), for: .normal)
        } else {
            self.endDate = date
            endPeriodButton.setTitle(formatter.string(from: date), for: .normal)
        }
    }
}
