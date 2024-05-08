
import UIKit

class ArchiveTimeController: UIViewController {
    
    @IBOutlet weak var bottomView: UIView! {
        didSet {
            bottomView.layer.cornerRadius = 16
        }
    }
    @IBOutlet weak var timePicker: UIPickerView!
    @IBOutlet weak var handle: UIView! {
        didSet {
            handle.layer.cornerRadius = 2
        }
    }
    @IBOutlet weak var viewHeight: NSLayoutConstraint!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var hoursLabel: UILabel!
    @IBOutlet weak var minutesLabel: UILabel!
    @IBOutlet weak var secondsLabel: UILabel!
    
    var backgroundColor = UIColor.clear
    
    var date = Date()
    
    private var height = CGFloat()
    private var maxHeight = CGFloat()
    
    weak var delegate: ChooseTimeDelegate?
    
    public var completionHandler: (() -> Void)?
    
    var startPosition: CGPoint!
    var translation: CGPoint!
    var originalHeight: CGFloat = 0
    var difference: CGFloat!
    
    var hour: Int = 0
    var minutes: Int = 0
    var seconds: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isSmallIPhone() {
            height = 301
            maxHeight = height + 50
        } else {
            height = 301
            maxHeight = height + 100
        }
        
        viewHeight.constant = height
        view.backgroundColor = backgroundColor
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(viewDidDragged(_:)))
        bottomView.addGestureRecognizer(panRecognizer)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewDidTapped(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        timePicker.selectRow(components.hour ?? 0, inComponent: 0, animated: false)
        timePicker.selectRow(components.minute ?? 0, inComponent: 1, animated: false)
        timePicker.selectRow(components.second ?? 0, inComponent: 2, animated: false)
        
        hour = components.hour ?? 0
        minutes = components.minute ?? 0
        seconds = components.second ?? 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let translations = delegate?.getTranslations()
        doneButton.setTitle(translations?.translate(.CheckDone), for: .normal)
        hoursLabel.text = translations?.translate(.HoursTitle)
        minutesLabel.text = translations?.translate(.MinutesTitle)
        secondsLabel.text = translations?.translate(.SecondsTitle)
    }
    
    @objc private func handleSwipe(_ gestureRecognizer: UISwipeGestureRecognizer) {
        completeAndDismiss()
    }
    
    public func completeAndDismiss() {
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
    
    @objc private func viewDidTapped(_ sender: UIPanGestureRecognizer) {
        if sender.state != .ended {
            return
        }
        let point = sender.location(in: view)
        
        if !bottomView.frame.contains(point) {
            completeAndDismiss()
        }
    }
    
    @IBAction func readyAction(_ sender: Any) {
        let newDate = Calendar.current.date(bySettingHour: hour, minute: minutes, second: seconds, of: date)
        
        delegate?.timeSelected(selectedTime: newDate ?? date)
        completeAndDismiss()
    }
}

extension ArchiveTimeController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 3
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0:
            return 24
        case 1,2:
            return 60

        default:
            return 0
        }
    }

    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return pickerView.frame.size.width/3
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return row < 10 ? "0\(row)" : "\(row)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0:
            hour = row
        case 1:
            minutes = row
        case 2:
            seconds = row
        default:
            break
        }
        
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 32)
        label.textColor = UIColor(hex: 0x262626)
        label.text = self.pickerView(pickerView, titleForRow: row, forComponent: component)
        label.textAlignment = .center
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 48
    }
}

