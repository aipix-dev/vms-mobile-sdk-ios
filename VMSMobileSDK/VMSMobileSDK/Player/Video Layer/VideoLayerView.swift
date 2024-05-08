

import UIKit

class VideoLayerView: UIView {
    
    private var currentPlayer: VideoPlayer?
    private var playerType: VMSPlayerOptions.VMSPlayerType = .rtspH264
    
    public func setup(type: VMSPlayerOptions.VMSPlayerType, withDelegate delegate: VideoPlayerDelegate) {
        playerType = type
        switch (type) {
//        case .hls:
//            let player = VideoPlayerHLS()
//            player.delegate = delegate
//            currentPlayer = player
        case .rtspH264:
            let player = VideoPlayerRTSPNative()
            player.delegate = delegate
            currentPlayer = player
        case .rtspH265:
            let player = VideoPlayerRTSPFFMPEG()
            player.delegate = delegate
            currentPlayer = player
        }
        currentPlayer?.setup(to: self)
    }
    
    public func currentPlayerType() -> VMSPlayerOptions.VMSPlayerType {
        return playerType
    }
    
    public func remove() {
        currentPlayer?.remove()
    }
    
    public func viewDidAppear() {
        currentPlayer?.viewDidAppear(in: self)
    }
    
    public func needsLayout() {
        self.setNeedsLayout()
    }
    
    public func updatePlayerFrame() {
        currentPlayer?.updateFrame(to: self.bounds)
    }
    
    public func play(hasSound: Bool, soundOn: Bool) {
        currentPlayer?.play(hasSound: hasSound, soundOn: soundOn)
    }
    
    public func pause(soundOn: Bool) {
        currentPlayer?.pause(soundOn: soundOn)
    }
    
    public func setVideoSpeed(_ speed: Double, from date: Date?) {
        currentPlayer?.playVideo(atSpeed: speed, fromDate: date ?? Date())
    }
    
    public func setVolume(_ volume: Float) {
        currentPlayer?.setVolume(volume)
    }
    
    public func hasSound() -> Bool {
        currentPlayer?.playerHasSound() ?? false
    }
    
    public func resignPlayer() {
        currentPlayer?.resignPlayer()
    }
    
    public func endPlayer() {
        currentPlayer?.endPlayer()
    }
    
    public func playerDate() -> Date? {
        currentPlayer?.playerDate()
    }
    
    func playArchiveUrl(_ url: URL, speed: Double) {
        currentPlayer?.playArchiveUrl(url)
//        currentPlayer?.playVideo(atspeed: speed, fromDate: Date())
    }
    
    func blockArchive() {
        currentPlayer?.playArchiveUrl(URL(fileURLWithPath: ""))
    }
    
    func getScreenshot() {
        currentPlayer?.getPlayerScreenshot()
    }
    
    public func getGravityResizeAspect() -> Bool {
        return currentPlayer?.getGravityResizeAspect() ?? false
    }
    public func toggleGravityResizeAspect() {
        currentPlayer?.setGravityResizeAspect(!getGravityResizeAspect())
    }
    public func setGravityResizeAspect(_ value: Bool) {
        currentPlayer?.setGravityResizeAspect(value)
    }
    
    public func getVideoRatio() -> CGFloat {
        return currentPlayer?.getVideoRatio() ?? 1
    }
    
    func playUrl(_ url: URL) {
        currentPlayer?.playUrl(url)
    }
    
    func reloadPlayer() {
        currentPlayer?.removeComponents()
        currentPlayer?.endPlayer()
    }
}
