
import UIKit

class ArchiveCalendarDayCell: UICollectionViewCell {
    
    @IBOutlet weak var selectionBackgroundView: UIView!
    @IBOutlet weak var numberLabel: UILabel!
    
    var day: ArchiveDay? {
        didSet {
            guard let day = day else { return }
            numberLabel.text = day.number
            accessibilityLabel = accessibilityDateFormatter.string(from: day.date)
            updateSelectionStatus()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        selectionBackgroundView.layer.cornerRadius = contentView.bounds.height / 2
    }
    
    private lazy var accessibilityDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.setLocalizedDateFormatFromTemplate("EEEE, MMMM d")
        return dateFormatter
    }()
    
    static let reuseIdentifier = String(describing: ArchiveCalendarDayCell.self)
}

private extension ArchiveCalendarDayCell {
    
    func updateSelectionStatus() {
        guard let day = day else { return }
        
        if day.isSelected {
            applySelectedStyle()
        } else if day.isToday {
            applyIsToday()
        } else if day.enabled {
            applyDefaultStyle(isWithinDisplayedMonth: day.isWithinDisplayedMonth)
        } else {
            applyDisabledStyle()
        }
    }
    
    func applyIsToday() {
        numberLabel.textColor = .black
        selectionBackgroundView.isHidden = false
        selectionBackgroundView.backgroundColor = .main.withAlphaComponent(0.2)
    }

    func applySelectedStyle() {
        accessibilityHint = nil
        numberLabel.textColor = .white
        selectionBackgroundView.isHidden = false
        selectionBackgroundView.backgroundColor = .main
    }

    func applyDefaultStyle(isWithinDisplayedMonth: Bool) {
        numberLabel.textColor = isWithinDisplayedMonth ? .black : .mainGrey.withAlphaComponent(0.5)
        selectionBackgroundView.isHidden = true
    }
    
    func applyDisabledStyle() {
        numberLabel.textColor = .mainGrey.withAlphaComponent(0.5)
        selectionBackgroundView.isHidden = true
    }
}
