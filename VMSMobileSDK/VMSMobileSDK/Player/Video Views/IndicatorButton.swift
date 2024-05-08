

import UIKit

@IBDesignable
class IndicatorButton: UIButton {
    
    enum IndicatorType: String {
        case live = "live"
        case archive = "archive"
        
        func textColor() -> UIColor {
            switch self {
            case .live:
                return .white
            case .archive:
                return .playerYellow
            }
        }
        
        func indicatorColor() -> UIColor {
            switch self {
            case .live:
                return .playerBlue
            case .archive:
                return .playerYellow
            }
        }
    }
    
    @IBInspectable var indicatorType: String? {
        willSet {
            if let newType = IndicatorType(rawValue: newValue?.lowercased() ?? "") {
                indType = newType
                indicatorView.backgroundColor = indType.indicatorColor()
                setTitleColor(indType.textColor(), for: .normal)
            }
        }
    }
    
    var indType = IndicatorType.live
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                setBackgroundImage(nil, for: .selected)
                setTitleColor(indType.textColor(), for: .selected)
                addSubview(indicatorView)
            } else {
                setTitleColor(.gray, for: .normal)
                indicatorView.removeFromSuperview()
            }
        }
    }
    
    var indicatorView = UIView()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        indicatorView.frame = CGRect(x: 0, y: bounds.height - 4, width: bounds.width, height: 8)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialization()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialization()
    }
    
    fileprivate func initialization() {
        clipsToBounds = true
        setBackgroundImage(nil, for: .selected)
        indicatorView.layer.cornerRadius = 4
    }
}
