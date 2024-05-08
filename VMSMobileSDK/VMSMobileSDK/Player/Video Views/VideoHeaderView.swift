

import UIKit

protocol VideoHeaderDelegate: AnyObject {
    func liveAction(onStart: Bool)
    func archiveAction(onStart: Bool)
}

class VideoHeaderView: UIView {
    
    @IBOutlet weak var liveButton: IndicatorButton!
    @IBOutlet weak var archiveButton: IndicatorButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var labelsStackView: UIStackView!
    
    public var isLive: Bool = true {
        didSet {
            liveButton.isSelected = isLive
            archiveButton.isSelected = !isLive
        }
    }
    
   weak var delegate: VideoHeaderDelegate?
    
    public var date: Date? {
        didSet {
            if let d = date {
                dateLabel.text = DateFormatter.yearMonthDay.string(from: d)
            }
        }
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
        backgroundColor = UIColor.init(red: 31, green: 33, blue: 40, alpha: 0.9)
    }
    
    public func reloadPermissions(isLiveAllowed: Bool = true, isArchiveAllowed: Bool) {
        if isArchiveAllowed {
            archiveButton.isHidden = false
        } else {
            archiveButton.isHidden = true
            if !isLive, isLiveAllowed {
                delegate?.liveAction(onStart: false)
                isLive = true
            }
        }
        if isLiveAllowed {
            liveButton.isHidden = false
        } else {
            liveButton.isHidden = true
            if isLive, isArchiveAllowed {
                delegate?.archiveAction(onStart: false)
                isLive = false
            }
        }
    }
    
    // user.hasPermission(.ArhivesShow)
    public func configure(_ name: String, archiveTitle: String, date: Date, isLiveAllowed: Bool = true, isArchiveAllowed: Bool) {
        archiveButton.isHidden = !isArchiveAllowed
        archiveButton.setTitle(archiveTitle, for: .normal)
        liveButton.isHidden = !isLiveAllowed
        dateLabel.textColor = UIColor.playerYellow
        nameLabel.text = name
        self.date = date
    }

    @IBAction func liveAction(_ sender: Any?) {
        delegate?.liveAction(onStart: false)
        
        isLive = true
    }
    
    @IBAction func archiveAction(_ sender: Any?) {
        delegate?.archiveAction(onStart: false)
        
        isLive = false
    }
}
