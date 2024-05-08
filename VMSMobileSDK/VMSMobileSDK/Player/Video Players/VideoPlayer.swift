

import UIKit

protocol VideoPlayer: AnyObject {
    func setup(to view: UIView)
    func remove()
    func viewDidAppear(in view: UIView)
    func play(hasSound: Bool, soundOn: Bool)
    func pause(soundOn: Bool)
    func setVolume(_ volume: Float)
    func playerHasSound() -> Bool
    func playVideo(atSpeed speed: Double, fromDate date: Date)
    func getPlayerScreenshot()
    func endPlayer()
    func resignPlayer()
    func playUrl(_ url: URL)
    func playArchiveUrl(_ url: URL)
    func getVideoRatio() -> CGFloat
    func playerDate() -> Date?
    func updateFrame(to bounds: CGRect)
    func getGravityResizeAspect() -> Bool
    func setGravityResizeAspect(_ value: Bool)
    func removeComponents()
}

protocol VideoPlayerDelegate: AnyObject {
    func playerItemDidReadyToPlay()
    func playerDidFail(message: String?)
    func playerPerformanceFail()
    func playerHasScreenshot(screenshot: UIImage?)
    func playerHasSound(hasSound: Bool)
    func playerNeedToRestart()
    func playerStartedToPlay()
}
