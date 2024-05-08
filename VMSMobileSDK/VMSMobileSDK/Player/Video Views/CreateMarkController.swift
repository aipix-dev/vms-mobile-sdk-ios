

import UIKit

protocol CreateMarkDelegate: AnyObject {
    func close()
    func createMark(markName: String, from: Date)
    func openPicker(withDate date: Date)
    func closeKeyboard()
    func openTimePicker(withDate date: Date)
    func editMark(markId: Int, markName: String, from: Date)
    func cancelEdit()
}

class CreateMarkController: UIViewController {
    
    @IBOutlet weak var stacksSpacing: NSLayoutConstraint!
    @IBOutlet weak var buttonsStackTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var nameField: PaddingTextField!
    @IBOutlet weak var dateTextView: UITextView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateAndTimeLabel: UILabel!
    
    weak var markCreationDelegate: CreateMarkDelegate?
    
    public var date: Date? {
        didSet {
            let month = localeDayMonth.string(from: date ?? Date())
            let time = hourMinuteSecond.string(from: date ?? Date())
            dateTextView.attributedText = createAtributedText(monthDayString: month, timeString: time)
            dateTextView.textContainerInset.top = 16
            dateTextView.textContainer.lineFragmentPadding = 12
        }
    }
    
    public var editMode: Bool?
    public var markToEdit: VMSEvent?
    public var translations: VMSPlayerTranslations!
    public var language: String!
    
    /**
    d MMM on locale language
    */
    var localeDayMonth: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM"
        dateFormatter.locale = VMSLocalization.getCurrentLocale(language: self.language)
        return dateFormatter
    }
    /**
     HH:mm:ss
     */
    var hourMinuteSecond: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        return dateFormatter
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dateTextView.delegate = self
        nameField.delegate = self
        doneButton.setTitle(translations.translate(.Done), for: .normal)
        cancelButton.setTitle(translations.translate(.Cancel), for: .normal)
        nameLabel.text = translations.translate(.MarkCreateTitle)
        dateAndTimeLabel.text = translations.translate(.MarkCreateDate)
        doneButton.backgroundColor = .buttonNormal
        nameField.returnKeyType = .done
        nameField.attributedPlaceholder = NSAttributedString(string: translations.translate(.MarkEmptyTitle), attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        if #available(iOS 13.0, *) {
            nameField.overrideUserInterfaceStyle = .light
        }
        
        smallPhoneConstraints()
        let textTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapOnText))
        textTapRecognizer.delegate = self
        dateTextView.addGestureRecognizer(textTapRecognizer)
        setElementsUI()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animateAlongsideTransition(in: self.view, animation: { [weak self] _ in
            self?.smallPhoneConstraints()
            }, completion: nil)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        view.endEditing(true)
    }
    
    @objc func tapOnText(_ sender: UITapGestureRecognizer) {

        let myTextView = sender.view as! UITextView
        let layoutManager = myTextView.layoutManager

        // location of tap in myTextView coordinates and taking the inset into account
        var location = sender.location(in: myTextView)
        location.x -= myTextView.textContainer.lineFragmentPadding
        location.y -= myTextView.textContainerInset.top
        if (location.y + myTextView.textContainerInset.top) > myTextView.textContainer.size.height { // если тыкнул ниже
            return
        }
        
        if (location.y + myTextView.textContainerInset.top) < myTextView.textContainerInset.top { // если тыкнул выше
            return
        }

        // character index at tap location
        let characterIndex = layoutManager.characterIndex(for: location, in: myTextView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        // if index is valid then do something.
        if characterIndex < myTextView.textStorage.length {

            // print the character index
//            print("character index: \(characterIndex)")
            
            // print the character at the index
            let myRange = NSRange(location: characterIndex, length: 1)
            let substring = (myTextView.attributedText.string as NSString).substring(with: myRange)
//            print("character at index: \(substring)")
            
            // check if the tap location has a certain attribute
            let dateAttribute = NSAttributedString.Key.dateAtributeName
            let dateAttributeValue = myTextView.attributedText?.attribute(dateAttribute, at: characterIndex, effectiveRange: nil)
            if let value = dateAttributeValue {
//                print("You tapped on \(dateAttribute.rawValue) and the value is: \(value)")
                if let date = date {
                    markCreationDelegate?.openPicker(withDate: date)
                }
            }
            
            let timeAttribute = NSAttributedString.Key.timeAtributeName
            let timeAttributeValue = myTextView.attributedText?.attribute(timeAttribute, at: characterIndex, effectiveRange: nil)
            if let _ = timeAttributeValue {
                if let date = date {
                    markCreationDelegate?.openTimePicker(withDate: date)
                }
            }
        }
    }
    
    public func setNameFieldText(_ text: String?) {
        nameField.text = text
        if let text = text, text != "" {
            doneButton.isEnabled = true
            doneButton.backgroundColor = doneButton.isEnabled ? UIColor.buttonNormal : UIColor.buttonDisabled
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        editMode ?? false ? markCreationDelegate?.cancelEdit() : markCreationDelegate?.close()
        nameField.text = translations.translate(.MarkNewTitle)
        editMode = nil
    }
    
    @IBAction func doneAction(_ sender: Any) {
        guard let name = nameField.text, let date = date else {return}
        if editMode ?? false {
            if let markToEdit = markToEdit, let markId = markToEdit.id {
                self.markToEdit = nil
                markCreationDelegate?.editMark(markId: markId, markName: name, from: date)
            } else {
                markCreationDelegate?.cancelEdit()
            }
        } else {
            markCreationDelegate?.createMark(markName: name, from: date)
        }
        
    }
    
    func setElementsUI() {
        nameField.layer.cornerRadius = 6.0
        dateTextView.layer.cornerRadius = 6.0
        doneButton.layer.cornerRadius = 6.0
        nameField.padding = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
    }
    
    func createAtributedText(monthDayString: String, timeString: String) -> NSMutableAttributedString {
        let monthStringAtr = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .medium),
                              NSAttributedString.Key.foregroundColor: UIColor(hex: 0xA6AAB4),
                              NSAttributedString.Key.dateAtributeName: "date"] as [NSAttributedString.Key : Any]
        
        let slashStringAtr = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .bold),
                              NSAttributedString.Key.foregroundColor: UIColor.init(hex: 0x272A33)]
        
        let timeStringAtr = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .medium),
                             NSAttributedString.Key.foregroundColor: UIColor(hex: 0xA6AAB4),
                             NSAttributedString.Key.timeAtributeName: "time"] as [NSAttributedString.Key : Any]
        
        let dateAtrString = NSMutableAttributedString(string: monthDayString, attributes: monthStringAtr)
        let slashAtrString = NSMutableAttributedString(string: "  /  ", attributes: slashStringAtr)
        let timeAtrString = NSMutableAttributedString(string: timeString, attributes: timeStringAtr)
        let fullString = NSMutableAttributedString()
        
        fullString.append(dateAtrString)
        fullString.append(slashAtrString)
        fullString.append(timeAtrString)
        return fullString
    }
    
    func smallPhoneConstraints() {
        if isSmallIPhone() {
            switch UIDevice.current.orientation {
            case .portrait, .portraitUpsideDown:
                self.buttonsStackTopConstraint.constant = 8
            default:
                self.buttonsStackTopConstraint.constant = 0
            }
            stacksSpacing.constant = 0
        }
    }
}

extension CreateMarkController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text, textField == nameField {
            let replacementText = (text as NSString).replacingCharacters(in: range, with: string)
            var enable = true
            if replacementText == "" {
                enable = false
            }
            doneButton.isEnabled = enable
            doneButton.backgroundColor = enable ? UIColor.buttonNormal : UIColor.buttonDisabled
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameField {
            view.endEditing(true)
        }
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        textField.layer.borderColor = UIColor.main.cgColor
        textField.layer.borderWidth = 1.0
        textField.layer.cornerRadius = 6.0
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        textField.layer.borderColor = UIColor.clear.cgColor
        textField.layer.borderWidth = 0
        textField.layer.cornerRadius = 6.0
        return true
    }
}

extension CreateMarkController: UITextViewDelegate {
    
}

extension CreateMarkController: UIGestureRecognizerDelegate {
    
}


