
import Foundation
import UIKit


public protocol VMSPlayerDelegate: AnyObject {
    
    /// Get called when player loaded and appeared on screen
    func playerDidAppear()
    
    /// Get called when player controller is deititializing
    func playerDidEnd()
    
    /// Get called when option button 'Events list' pressed
    func gotoEventsList(camera: VMSCamera)
    
    /// Get called when button 'mute/unmuted' pressed
    func soundChanged(isOn: Bool)
    
    /// Get called when new quality option is chosen
    func qualityChanged(quality: VMSStream.QualityType)
    
    /// Get called when new player type is chosen
    func playerTypeChanged(type: VMSPlayerOptions.VMSPlayerType)
    
    /// Get called when screenshot captured fom current frame
    func screenshotCreated(image: UIImage, cameraName: String, date: Date)
    
    /// Get called when filter for marks applied
    func marksFiltered(markTypes: [VMSEventType])
    
    /// If you want to log user activity, this method provides the action's names to transfer to your app.
    func logPlayerEvent(event: String)
    
    /// Show player error
    func playerDidReceiveError(message: String)
    
    /// Show player info
    func playerDidReceiveInfo(message: String)
    
    /// If you show views for error that have life time, dismiss them
    func dismissPlayerErrors()
    
    /// if you want to store is user asked for network connection
    func isUserAllowForNet()
}

public extension VMSPlayerDelegate {
    
    func playerDidAppear() {
        // Optional method
    }
    
    func playerDidEnd() {
        // Optional method
    }
    
    func soundChanged(isOn: Bool) {
        // Optional method
    }
    
    func qualityChanged(quality: VMSStream.QualityType) {
        // Optional method
    }
    
    func marksFiltered(markTypes: [VMSEventType]) {
        // Optional method
    }
    
    func logPlayerEvent(event: String) {
        // Optional method
    }
    
    func playerDidReceiveInfo(message: String) {
        // Optional method
    }
}

/// Player respond to these notification names in order to handle them
extension Notification.Name {
    static let noConnectionError = Notification.Name("noConnectionError")
    static let updateUserPermissions = Notification.Name("updateUserPermissions")
    static let updateUserCameras = Notification.Name("updateUserCameras")
    static let updateMarks = Notification.Name("updateMarks")
    static let updateMark = Notification.Name("updateMark")
    static let resumePlayback = Notification.Name("resumePlayback")
}
