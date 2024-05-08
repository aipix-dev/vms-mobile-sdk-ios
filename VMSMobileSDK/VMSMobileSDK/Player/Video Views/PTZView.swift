

import UIKit

class PTZView: UIView {
    
    @IBOutlet weak var upButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var defaultsButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var downButton: UIButton!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!
    
    private var cameraId: Int = 0
    private var isVibrationAllowed: Bool = false
    private var playerApi: PlayerApi?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //custom logic goes here
        initialization()
    }
    
    fileprivate func initialization() {
        
        for subView in self.subviews {
            if subView is UIButton {
                subView.layer.cornerRadius = 24
                subView.backgroundColor = UIColor.init(hex: 0x1F2128, alpha: 0.7)
            }
        }
    }
    
    public func configure(allowVibration: Bool, cameraId: Int, api: PlayerApi) {
        self.isVibrationAllowed = allowVibration
        self.cameraId = cameraId
        self.playerApi = api
    }
    
    // MARK: - Actions
    
    @IBAction func moveUp(_ sender: Any) {
        moveCamera(direction: .up)
        UIDevice.vibrate(isAllowed: isVibrationAllowed)
    }
    
    @IBAction func moveLeft(_ sender: Any) {
        moveCamera(direction: .left)
        UIDevice.vibrate(isAllowed: isVibrationAllowed)
    }
    
    @IBAction func moveHome(_ sender: Any) {
        moveHome()
        UIDevice.vibrate(isAllowed: isVibrationAllowed)
    }
    
    @IBAction func moveRight(_ sender: Any) {
        moveCamera(direction: .right)
        UIDevice.vibrate(isAllowed: isVibrationAllowed)
    }
    
    @IBAction func moveDown(_ sender: Any) {
        moveCamera(direction: .down)
        UIDevice.vibrate(isAllowed: isVibrationAllowed)
    }
    
    @IBAction func zoomOut(_ sender: Any) {
        moveCamera(direction: .zoomOut)
        UIDevice.vibrate(isAllowed: isVibrationAllowed)
    }
    
    @IBAction func zoomIn(_ sender: Any) {
        moveCamera(direction: .zoomIn)
        UIDevice.vibrate(isAllowed: isVibrationAllowed)
    }
    
    //MARK: - Server
    private func moveCamera(direction: VMSPTZDirection) {
        playerApi?.moveCamera(with: cameraId, direction: direction, completion: { _ in
        })
    }
    
    private func moveHome() {
        playerApi?.moveCameraHome(with: cameraId, completion: { _ in
        })
    }
    
}
