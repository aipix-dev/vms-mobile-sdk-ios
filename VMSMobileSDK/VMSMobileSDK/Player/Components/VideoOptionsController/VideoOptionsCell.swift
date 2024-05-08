
import UIKit

class VideoOptionsCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var checkmarkImage: UIImageView!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var optionsImageView: UIImageView!
    
    @IBOutlet weak var customSpeedStack: UIStackView!
    @IBOutlet weak var speedImageView: UIImageView!
    @IBOutlet weak var speedLabel: UILabel!
    
    private var mainOptionImage = UIImage()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    public var currentSpeed: Double = 1
    
    public var currentQuality: VideoQuality = .high {
        didSet {
            switch currentQuality {
            case .high:
                mainOptionImage = UIImage(named: "stream_hd_black", in: Bundle(for: VMSPlayerController.self), with: nil) ?? UIImage()
            case .low:
                mainOptionImage = UIImage(named: "stream_sd_black", in: Bundle(for: VMSPlayerController.self), with: nil) ?? UIImage()
            }
        }
    }

    public func configure(_ title: String, details: String?, selected: Bool, isBottom: Bool = false) {
        titleLabel.text = title
        detailLabel.text = details
        detailLabel.isHidden = details == nil
        checkmarkImage.image = selected ? UIImage(named: "checkmark", in: Bundle(for: VMSPlayerController.self), with: nil) : nil
        checkmarkImage.setTintColor()
        separatorView.isHidden = isBottom
    }
    
    private func createAtributedString(_ string: String, _ string2: String?) -> NSMutableAttributedString {
        let atrString = NSMutableAttributedString()
        let firstStringAtr = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .semibold)]
        let secondStringAtr = [NSAttributedString.Key.foregroundColor : UIColor.gray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16, weight: .semibold)]
        let firstString = NSMutableAttributedString(string: string, attributes: firstStringAtr)
        
        atrString.append(firstString)
        
        if let secondString = string2 {
            let secondAtributedString = NSMutableAttributedString(string: (" • \(secondString)"), attributes: secondStringAtr)
            atrString.append(secondAtributedString)
        }
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.allowsDefaultTighteningForTruncation = true
        return atrString
    }
    
    public func configureComplexCell(title: String, details: String?, imageName: String?, isDisabled: Bool) {
        optionsImageView.isHidden = imageName == nil
        checkmarkImage.isHidden = true
        detailLabel.isHidden = true
        separatorView.isHidden = false
        let optionsImage = UIImage(named: imageName ?? "", in: Bundle(for: VMSPlayerController.self), with: nil)
        optionsImageView.image = optionsImage
        titleLabel.attributedText = createAtributedString(title, details)
        separatorView.isHidden = true
        
        if isDisabled {
            titleLabel.textColor = UIColor.init(hex: 0xACAFB8)
            optionsImageView.image = optionsImage?.withRenderingMode(.alwaysTemplate)
            optionsImageView.tintColor = UIColor.init(hex: 0xACAFB8)
        }
    }
    
    public func configureSelectionCell(title: String, isSelected: Bool) {
        optionsImageView.isHidden = true
        checkmarkImage.isHidden = false
        detailLabel.isHidden = true
        separatorView.isHidden = true
        titleLabel.text = title
        checkmarkImage.image = isSelected ? UIImage(named: "checkmark", in: Bundle(for: VMSPlayerController.self), with: nil) : nil
        checkmarkImage.setTintColor()
    }
    
}
