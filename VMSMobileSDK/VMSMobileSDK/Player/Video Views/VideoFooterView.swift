
import UIKit

protocol VideoFooterViewDelegate: AnyObject {
    func rewindPlayer(_ component: Calendar.Component, value: Int)
}

class VideoFooterView: UIView {
    
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var minus24Button: UIButton!
    @IBOutlet weak var minusHourButton: UIButton!
    @IBOutlet weak var minusMinuteButton: UIButton!
    @IBOutlet weak var minusSecButton: UIButton!
    
    @IBOutlet weak var plusSecButton: UIButton!
    @IBOutlet weak var plusMinuteButton: UIButton!
    @IBOutlet weak var plusHourButton: UIButton!
    @IBOutlet weak var plus24Button: UIButton!
    @IBOutlet weak var screenshotButton: UIButton!
    
    weak var delegate: VideoFooterViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialization()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialization()
    }
    
    fileprivate func initialization() {
    }
    
    // user.hasPermission(.ArhivesPreviewDownload)
    public func configurePlayer(_ isPlaying: Bool, screenshotAllowed: Bool, isMarkCreationMode: Bool) {
        screenshotButton.alpha = screenshotAllowed ? 1 : 0
        playPauseButton.alpha = isMarkCreationMode ? 0.4 : 1
        playPauseButton.setImage(
            isPlaying
            ? UIImage(named: "pause_video", in: Bundle(for: VMSPlayerController.self), with: nil)
            : UIImage(named: "play_video", in: Bundle(for: VMSPlayerController.self), with: nil), for: .normal)
    }
    
    public func enableButtons(_ enable: Bool) {
        minus24Button.isEnabled = enable
        minusHourButton.isEnabled = enable
        minusMinuteButton.isEnabled = enable
        minusSecButton.isEnabled = enable
        
        plus24Button.isEnabled = enable
        plusHourButton.isEnabled = enable
        plusMinuteButton.isEnabled = enable
        plusSecButton.isEnabled = enable
    }
    
    public func enableRewindButtons(rightDifference: Double, leftDiference: Double) {
        
        plusSecButton.isEnabled = rightDifference > 5
        plusMinuteButton.isEnabled = rightDifference > 60
        plusHourButton.isEnabled = rightDifference > 3600
        plus24Button.isEnabled = rightDifference > 86400
        
        minusSecButton.isEnabled = leftDiference > 5
        minusMinuteButton.isEnabled = leftDiference > 60
        minusHourButton.isEnabled = leftDiference > 3600
        minus24Button.isEnabled = leftDiference > 86400
    }
    
    @IBAction func plus5sec(_ sender: Any?) {
        delegate?.rewindPlayer(.second, value: 5)
    }
    
    @IBAction func plus1min(_ sender: Any?) {
        delegate?.rewindPlayer(.minute, value: 1)
    }
    
    @IBAction func plus1hour(_ sender: Any?) {
        delegate?.rewindPlayer(.hour, value: 1)
    }
    
    @IBAction func plus24hour(_ sender: Any?) {
        delegate?.rewindPlayer(.day, value: 1)
    }
    
    @IBAction func minus5sec(_ sender: Any?) {
        delegate?.rewindPlayer(.second, value: -5)
    }
    
    @IBAction func minus1min(_ sender: Any?) {
        delegate?.rewindPlayer(.minute, value: -1)
    }
    
    @IBAction func minus1hour(_ sender: Any?) {
        delegate?.rewindPlayer(.hour, value: -1)
    }
    
    @IBAction func minus24hour(_ sender: Any?) {
        delegate?.rewindPlayer(.day, value: -1)
    }
}
