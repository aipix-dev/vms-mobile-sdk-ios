

import UIKit
import AVFoundation

final class VideoPlayerHLS: VideoPlayer {
    func removeComponents() {
        
    }
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var output: AVPlayerItemVideoOutput? = AVPlayerItemVideoOutput(pixelBufferAttributes: Dictionary<String, AnyObject>())
    
    public var videoRatio: CGFloat = 1.0
    
    public var isGravityResizeAspect: Bool = true {
        didSet {
            playerLayer?.videoGravity = isGravityResizeAspect ? .resizeAspect : .resize
        }
    }
    
    public weak var delegate: VideoPlayerDelegate?
    
    private var observer: NSKeyValueObservation?
    
    // MARK: - PRIVATE
    
    private func handleAVPlayerAccess(playerItem: AVPlayerItem) {

        guard let lastEvent = playerItem.accessLog()?.events.last else {
            return
        }

        let indicatedBitrate = lastEvent.indicatedBitrate

        /*
        print("--------------PLAYER LOG--------------")
        print("EVENT: \(lastEvent)")
        print("INDICATED BITRATE: \(indicatedBitrate)")
        print("PLAYBACK RELATED LOG EVENTS")
        print("PLAYBACK START DATE: \(String(describing: lastEvent.playbackStartDate))")
        print("PLAYBACK SESSION ID: \(String(describing: lastEvent.playbackSessionID))")
        print("PLAYBACK START OFFSET: \(lastEvent.playbackStartOffset)")
        print("PLAYBACK TYPE: \(String(describing: lastEvent.playbackType))")
        print("STARTUP TIME: \(lastEvent.startupTime)")
        print("DURATION WATCHED: \(lastEvent.durationWatched)")
        print("NUMBER OF DROPPED VIDEO FRAMES: \(lastEvent.numberOfDroppedVideoFrames)")
        print("NUMBER OF STALLS: \(lastEvent.numberOfStalls)")
        print("SEGMENTS DOWNLOADED DURATION: \(lastEvent.segmentsDownloadedDuration)")
        print("DOWNLOAD OVERDUE: \(lastEvent.downloadOverdue)")
        print("--------------------------------------")
         */
    }
    
    private func playerItemDidReadyToPlay() { // вызывается, когда плеер может начать играть видео.
        delegate?.playerItemDidReadyToPlay()
        setVideoRatio()
    }
    
    private func setVideoRatio() {
        let width = self.player?.currentItem?.presentationSize.width
        let height = self.player?.currentItem?.presentationSize.height
        if let width = width, let height = height, width != 0, height != 0 {
            videoRatio = width / height
        }
    }
    
    // MARK: - PUBLIC
    
    public func setup(to view: UIView) {
        player = AVQueuePlayer(playerItem: nil)
        playerLayer = AVPlayerLayer(player: player)
        updateFrame(to: view.bounds)
        view.layer.insertSublayer(playerLayer!, at: 0)
        player?.volume = 0
    }
    
    public func remove() {
        playerLayer?.removeFromSuperlayer()
    }
    
    public func viewDidAppear(in view: UIView) {
        isGravityResizeAspect = true
        updateFrame(to: view.bounds)
    }
    
    public func updateFrame(to bounds: CGRect) {
        playerLayer?.frame = bounds
    }
    
    public func getGravityResizeAspect() -> Bool {
        return isGravityResizeAspect
    }
    
    public func setGravityResizeAspect(_ value: Bool) {
        isGravityResizeAspect = value
    }
    
    public func getVideoRatio() -> CGFloat {
        return videoRatio
    }
    
    func play(hasSound: Bool, soundOn: Bool) {
        player?.play()
    }
    
    public func pause(soundOn: Bool) {
        player?.pause()
    }
    
    public func setVolume(_ volume: Float) {
        player?.volume = volume
        if volume > 0 {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            } catch(let error) {
//                print(error.localizedDescription)
            }
        }
    }
    
    func playerHasSound() -> Bool {
        return false
    }
    
    public func playVideo(atSpeed speed: Double, fromDate date: Date) {
        
        if speed <= 1 {
            self.player?.currentItem?.audioTimePitchAlgorithm = .lowQualityZeroLatency
            self.player?.rate = Float(speed)
        } else {
            self.player?.currentItem?.audioTimePitchAlgorithm = .timeDomain
            self.player?.rate = Float(speed)
        }
    }
    
    public func getPlayerScreenshot() {
        guard let time = self.player?.currentTime() else { return }
        guard let pixelBuffer = self.output?.copyPixelBuffer(forItemTime: time,
                                                            itemTimeForDisplay: nil) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        let temporaryContext = CIContext(options: nil)
        let rect = CGRect(x: 0, y: 0,
                          width: CGFloat(CVPixelBufferGetWidth(pixelBuffer)),
                          height: CGFloat(CVPixelBufferGetHeight(pixelBuffer)))
        guard let videoImage = temporaryContext.createCGImage(ciImage, from: rect) else {
            return
        }
        delegate?.playerHasScreenshot(screenshot: UIImage(cgImage: videoImage))
    }
    
    public func resignPlayer() {
        player?.replaceCurrentItem(with: nil)
    }
    
    public func endPlayer() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        player = nil
        observer?.invalidate()
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemNewAccessLogEntry, object: nil)
    }
    
    public func playerDate() -> Date? {
        return player?.currentItem?.currentDate()
    }
    
    public func playUrl(_ url: URL) {
        
        autoreleasepool {
            let asset = AVAsset(url: url)
                
                let assetKeys = [
                    "playable",
                    "hasProtectedContent"
                ]
            
            let playerItem = AVPlayerItem(asset: asset,
                                          automaticallyLoadedAssetKeys: assetKeys)
            
            if let out = self.output {
                self.player?.currentItem?.remove(out)
            }
            self.output = nil
            let output = AVPlayerItemVideoOutput(pixelBufferAttributes: Dictionary<String, AnyObject>())
            self.output = output
//            print("LIVE url: \(url)")
            playerItem.add(self.output ?? output)
            
            self.observer = playerItem.observe(\.status, options:  [.new, .old], changeHandler: { (playerItem, change) in
                    if playerItem.status == .readyToPlay {
                        self.playerItemDidReadyToPlay()
                    } else {
                        self.delegate?.playerDidFail(message: playerItem.error?.localizedDescription)
                    }
                })
            
            self.player?.replaceCurrentItem(with: playerItem)
        }
    }
    
    public func playArchiveUrl(_ url: URL) {
        let asset = AVAsset(url: url)
            
            let assetKeys = [
                "playable",
                "hasProtectedContent"
            ]
        
        let playerItem = AVPlayerItem(asset: asset,
                                      automaticallyLoadedAssetKeys: assetKeys)
        let output = AVPlayerItemVideoOutput(pixelBufferAttributes: Dictionary<String, AnyObject>())
        self.output = output
//        print("ARCHIVE url: \(url)")
        playerItem.add(self.output ?? output)
        
        self.observer = playerItem.observe(\.status, options:  [.new, .old], changeHandler: { (playerItem, change) in
                if playerItem.status == .readyToPlay {
                    self.handleAVPlayerAccess(playerItem: playerItem)
                    self.playerItemDidReadyToPlay()
                } else {
                    self.delegate?.playerDidFail(message: playerItem.error?.localizedDescription)
                }
            })
        
        self.player?.replaceCurrentItem(with: playerItem)
    }
}
