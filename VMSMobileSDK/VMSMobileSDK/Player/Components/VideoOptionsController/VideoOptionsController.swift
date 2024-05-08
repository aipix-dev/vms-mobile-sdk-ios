
import UIKit

class VideoOptionsController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var viewHeight: NSLayoutConstraint!
    @IBOutlet weak var tableTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var handle: UIView! {
        didSet {
            handle.layer.cornerRadius = 2
        }
    }
    
    @IBOutlet weak var bottomView: UIView! {
        didSet {
            bottomView.layer.cornerRadius = 16
        }
    }
    
    var translation: CGPoint!
    var startPosition: CGPoint!
    var originalHeight: CGFloat = 0
    var difference: CGFloat!
    
    private var height = CGFloat()
    private var maxHeight = CGFloat()
    
    private var type: VideoOptionType!
    private var chosenOptions: [String] = []
    
    private var translations: VMSPlayerTranslations!
    private var allowVibration: Bool = true
    
    private var handler: (([String]) -> Void)?
    
    static func initialization(type: VideoOptionType, translations: VMSPlayerTranslations, allowVibration: Bool, handler: (([String]) -> Void)?) ->VideoOptionsController {
        let storyboard = UIStoryboard.init(name: "VMSPlayer", bundle: Bundle(for: self))
        let controller = storyboard.instantiateViewController(withIdentifier: "VideoOptionsController") as! VideoOptionsController
        controller.translations = translations
        controller.type = type
        controller.allowVibration = allowVibration
        controller.handler = handler
        controller.modalPresentationStyle = .overFullScreen
        controller.modalTransitionStyle = .coverVertical
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var dataCount = 0
        switch type {
        case .separation(let data):
            titleLabel.isHidden = true
            titleImage.isHidden = true
            tableTopConstraint.isActive = false
            tableView.topAnchor.constraint(equalTo: handle.bottomAnchor, constant: 8).isActive = true
            dataCount = data.count
            height = deviceHasNotch ? CGFloat(dataCount * 50 + 100) : CGFloat(dataCount * 50 + 50)
        case .singleSelection(let data):
            titleLabel.text = data.title
            titleImage.image = UIImage(named: data.imageName ?? "", in: Bundle(for: VMSPlayerController.self), with: nil)
            dataCount = data.options.count
            chosenOptions = [data.chosenOption]
            height = deviceHasNotch ? CGFloat(dataCount * 50 + 136) : CGFloat(dataCount * 50 + 90)
        case .multiSelection(let data):
            titleLabel.text = data.title
            titleImage.image = UIImage(named: data.imageName ?? "", in: Bundle(for: VMSPlayerController.self), with: nil)
            dataCount = data.options.count
            chosenOptions = data.chosenOptions
            height = deviceHasNotch ? CGFloat(dataCount * 50 + 196) : CGFloat(dataCount * 50 + 146)
            saveButton.isHidden = false
        case .none:
            break
        }
        
        let maxDeviceHeight = UIScreen.main.bounds.height - 100
        height = min(height, maxDeviceHeight)
        
        let padding: CGFloat = isSmallIPhone() ? 50.0 : 100.0
        
        viewHeight.constant = height
        maxHeight = min(viewHeight.constant + padding, maxDeviceHeight)
        originalHeight = height
        
        view.layoutSubviews()
        
        view.backgroundColor = .clear
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(viewDidDragged(_:)))
        bottomView.addGestureRecognizer(panRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        saveButton.setTitle(translations.translate(.ApplySelected), for: .normal)
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
    
    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: view)
        if point.y < bottomView.frame.origin.y {
            completeAndDismiss()
        }
    }
    
    @IBAction func saveAction() {
        completeAndDismiss()
        handler?(chosenOptions)
    }
}

extension VideoOptionsController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch type {
        case .separation(let data):
            return data.count
        case .singleSelection(let data):
            return data.options.count
        case .multiSelection(let data):
            return data.options.count
        case .none:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "VideoOptionsCell") as? VideoOptionsCell else {
            return UITableViewCell()
        }
        switch type {
        case .separation(let data):
            let item = data[indexPath.row]
            cell.configureComplexCell(title: item.title, details: item.details, imageName: item.imageName, isDisabled: item.isDisabled)
            if item.isDisabled {
                cell.selectionStyle = .none
            }
        case .singleSelection(let data):
            let item = data.options[indexPath.row]
            cell.configureSelectionCell(title: item, isSelected: chosenOptions.contains(item))
        case .multiSelection(let data):
            let item = data.options[indexPath.row]
            cell.configureSelectionCell(title: item, isSelected: chosenOptions.contains(item))
        case .none:
            break
        }
        return cell
    }
    
}

// MARK: - UITableViewDelegate

extension VideoOptionsController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch type {
        case .separation(let data):
            let item = data[indexPath.row]
            if item.isDisabled {
                return
            }
            completeAndDismiss()
            handler?([item.title])
        case .singleSelection(let data):
            let chosen = [data.options[indexPath.row]]
            chosenOptions = chosen
            tableView.reloadData()
            completeAndDismiss()
            handler?(chosen)
        case .multiSelection(let data):
            let chosen = data.options[indexPath.row]
            if data.defaultOptions.contains(chosen) {
                chosenOptions = [chosen]
            } else if !data.defaultOptions.contains(chosen), let index: Int = chosenOptions.firstIndex(of: chosen) {
                chosenOptions.remove(at: [index])
                if chosenOptions.isEmpty, let defaultValue = data.defaultOptions.first {
                    chosenOptions.append(defaultValue)
                }
            } else {
                chosenOptions.append(chosen)
                for defaultValue in data.defaultOptions {
                    chosenOptions.removeAll { value in
                        return value == defaultValue
                    }
                }
            }
            tableView.reloadData()
            UIDevice.vibrate(isAllowed: allowVibration)
        case .none:
            break
        }
    }
}
