//
//  VideoPlayerRTSPFFMPEG.swift
//  VMSMobileSDK
//
//  Created by Anton Smirnov on 22.03.24.
//

import UIKit

class VideoPlayerRTSPFFMPEG: VideoPlayer {
    
    private var imageView = UIImageView()
    private var video: RTSPPlayerFFMPEG?
    private var videoQueue: DispatchWorkItem?
    
    private var startPlayDate: Date?
    private var currentPlayDate: Date?
    private var hasSound: Bool = false
    private var canPlaySound: Bool?
    private var soundOn: Bool = false {
        didSet {
            //            soundOn ? video?.playAudio() : video?.pauseAudio()
        }
    }
    public var videoRatio: CGFloat = 1.0
    private var currentSpeed: Double = 1.0
    private var components: URLComponents?
    private var retryAttemps: Int = 0
    private var isPlayingCounter: Int = 0
    
    deinit {
        resignPlayer()
        removeComponents()
        print("DEINIT VIDEO LAYER")
    }
    
    // MARK: - PUBLIC
    
    public var isGravityResizeAspect: Bool = true {
        didSet {
            //            playerLayer?.videoGravity = isGravityResizeAspect ? .resizeAspect : .resize
        }
    }
    
    public func setup(to view: UIView) {
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        imageView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
    }
    
    public func remove() {
        imageView.removeFromSuperview()
    }
    
    public func viewDidAppear(in view: UIView) {
        isGravityResizeAspect = true
    }
    
    internal func updateFrame(to bounds: CGRect) {
    }
    
    public func getGravityResizeAspect() -> Bool {
        return isGravityResizeAspect
    }
    
    public func setGravityResizeAspect(_ value: Bool) {}
    
    public func getVideoRatio() -> CGFloat {
        return videoRatio
    }
    
    public func setVolume(_ volume: Float) {
        soundOn = volume == 1 ? true : false
    }
    
    public func playerHasSound() -> Bool {
        return canPlaySound ?? false
    }
    
    public func getPlayerScreenshot() {
        guard let videoImage = video?.currentImage else {
            return
        }
        delegate?.playerHasScreenshot(screenshot: videoImage)
    }
    
    public func endPlayer() {
        startPlayDate = nil
        resignPlayer()
        imageView.image = UIImage()
    }
    
    public func playerDate() -> Date? {
        guard let sdpStartTime = video?.sdpStartTime, sdpStartTime > 0 else {
            return playbackDate(startPlayDate)
        }
        return playbackDate(Date(timeIntervalSince1970: sdpStartTime))
    }
    
    /**
     Calculating playback date across current playback time
     */
    private func playbackDate(_ startPlayDate: Date?) -> Date? {
        return startPlayDate?.addingTimeInterval((video?.currentTime ?? 0) * currentSpeed)
    }
    
    func play(hasSound: Bool, soundOn: Bool) {
        if video != nil {
            self.hasSound = hasSound
            self.soundOn = soundOn
            reinitializePlayerLayer()
        }
    }
    
    public func pause(soundOn: Bool) {
        self.soundOn = soundOn
        self.startPlayDate = self.playerDate()
        let image = self.video?.currentImage
        self.resignPlayer()
        self.imageView.image = image == nil ? UIImage() : image
    }
    
    private var timer: Timer?
    
    private var _isPlaying: Bool = false
    var isPlaying: Bool {
        set {
            setPlayStatus(newValue)
            _isPlaying = newValue
        }
        get {
            return _isPlaying
        }
    }
    
    public weak var delegate: VideoPlayerDelegate?
    
    // MARK: - PRIVATE
    
    private func setVideoRatio() {
        let image = video?.currentImage
        let width = image?.size.width
        let height = image?.size.height
        
        if let width = width, let height = height, width != 0, height != 0 {
            videoRatio = width / height
        }
    }
    
    @objc fileprivate func updatePlayer() {
        DispatchQueue.main.async {
            if let video = self.video {
                do {
                    try video.stepVideoFrame(self.soundOn)
                    if let image = video.currentImage {
                        if (self.canPlaySound == nil) {
                            self.canPlaySound = video.canPlayAudio()
                            self.delegate?.playerHasSound(hasSound: video.canPlayAudio())
                        }
                        if self.isPlayingCounter > 90 && !self.isPlaying {
                            self.isPlaying = true
                            self.setVideoRatio()
                        } else if !self.isPlaying {
                            self.isPlayingCounter += 1
                        }
                        self.imageView.image = image
                    }
                } catch let error as NSError {
                    self.playerDidFail(error)
                }
            } else {
//                self.playerDidFail(nil)
            }
        }
    }
    
    private func playerDidFail(_ error: NSError?) {
        
        DispatchQueue.main.async {
            guard let error = error else {
                print("LOG PLAYER INIT ERROR: Something went wrong")
                self.endPlayer()
                self.delegate?.playerDidFail(message: nil)
                return
            }
            
            if error.domain == "FFMPEGPlaybackError" {
                print("LOG PLAY VIDEO ERROR: \(String(describing: error.localizedDescription))")
                
                self.retryAttemps += 1
                
                if self.retryAttemps > 2 {
                    self.endPlayer()
                    self.delegate?.playerDidFail(message: nil)
                    self.retryAttemps = 0
                    print("LOG PLAYER RETRY ATTEMPS REACHED: \(String(describing: error.localizedDescription))")
                    return
                }
                self.endPlayer()
                self.delegate?.playerNeedToRestart()
                return
            }
            
            // Here we are checking that the timeout has returned to the URL we are trying to play. There may be a situation, while navigating the timeline, the timeout may return to the previous URL that we no longer need."
            if error.domain == "FFMPEGInitTimeout" {
                print("LOG PLAY VIDEO ERROR: \(String(describing: error.localizedDescription))")
                guard let url = error.localizedFailureReason, !url.isEmpty, let currentUrl = self.components?.url else { return }
                if url == currentUrl.absoluteString {
                    self.endPlayer()
                    self.delegate?.playerDidFail(message: nil)
                    return
                }
                return
            }
            
            if error.domain == "FFMPEGPlaybackPerformanceError" {
                print("LOG PLAY PERFORMANCE ERROR: \(String(describing: error.localizedDescription))")
                self.endPlayer()
                self.components = nil
                self.delegate?.playerPerformanceFail()
                return
            }
            // We can show what exactly happening
            print("LOG PLAYER ERROR: \(String(describing: error.localizedDescription))")
            //            self.delegate?.playerDidFail(error: .errorWith(error.localizedDescription))
            self.endPlayer()
            self.components = nil
            self.delegate?.playerDidFail(message: nil)
        }
    }
    
    @objc fileprivate func reinitializePlayerLayer() {
        if timer != nil {
            stopTimer()
            isPlayingCounter = 0
        }
        let speed = 1.0 / currentSpeed / Double(video?.frameRate ?? 30)
        timer = Timer.scheduledTimer(timeInterval: speed, target: self, selector: #selector(VideoPlayerRTSPFFMPEG.updatePlayer), userInfo: nil, repeats: true)
        timer?.fire()
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkPlayerRunning() {
        self.reinitializePlayerLayer()
    }
    
    private func setPlayStatus(_ newStatus: Bool) {
        if !isPlaying, newStatus {
            delegate?.playerStartedToPlay()
        }
    }
    
    // MARK: - PUBLIC
    
    public func resignPlayer() {
        isPlayingCounter = 0
        stopTimer()
        canPlaySound = nil
        isPlaying = false
        imageView.image = UIImage()
        video?.closeAudio()
        video?.cancel()
        video = nil
        videoQueue?.cancel()
        videoQueue = nil
    }
    
    /**
     Main start point for playing video from archive. For archive we use components to set timestamp and speed.
     For live streams make sure you don't have saved components in order to let live stream url untouched.
     */
    
    public func playVideo(atSpeed speed: Double, fromDate date: Date) {
        
        /**
         Now we ignore the date parameter for all across resume playng, since we get the timestamp in the URL to play the archive.
         */
        
        guard var comps = components, let url = comps.url else { return }
        resignPlayer()
        
        currentSpeed = speed
        
        print("LOG: inner date \(date)")
        
        let queryNamesToRemove = Set(["timestamp", "speed", "time"])
        
        comps.queryItems?.removeAll { query in
            return queryNamesToRemove.contains(query.name)
        }
        
        if let timeStamp = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "timestamp" })?.value {
            let date = Date(timeIntervalSince1970: Double(timeStamp) ?? 0)
            let time = DateFormatter.playerFormat.string(from: date)
            comps.queryItems?.append(URLQueryItem(name: "time", value: time))
            print("LOG: url date \(date)")
        } else if URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "time" })?.value != nil {
            let time = DateFormatter.playerFormat.string(from: date)
            comps.queryItems?.append(URLQueryItem(name: "time", value: time))
            print("LOG: url date \(date)")
        }
        
        comps.queryItems?.append(URLQueryItem(name: "speed", value: speed.cleanString()))
        self.components = comps
        
        guard let newUrl = comps.url, let queryItems = comps.queryItems, !queryItems.isEmpty  else { return }
        playUrl(newUrl)
    }
    
    public func playUrl(_ url: URL) {
        resignPlayer()
        print("LOG PLAYER URL:\n\(url.absoluteString)")
        let videoQueueItem = DispatchWorkItem.init(qos: .userInteractive, block: {
            self.startPlayer(url)
        })
        
        videoQueue = videoQueueItem
        
        DispatchQueue.global(qos: .userInitiated).async(execute: videoQueueItem)
        
        self.checkPlayerRunning()
    }
    
    private func startPlayer(_ url: URL) {
        do {
            try self.video = RTSPPlayerFFMPEG(video: url.absoluteString, speed: currentSpeed, withAudio: true)
        } catch let error as NSError {
            DispatchQueue.main.async {
                self.playerDidFail(error)
            }
        }
        if self.startPlayDate == nil {
            self.startPlayDate = Date()
        }
    }
    
    public func playArchiveUrl(_ url: URL) {
        components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let componentsItems = components?.queryItems else { return }
        if let from = components?.queryItems?.first(where: {$0.name == "from"})?.value {
            startPlayDate = DateFormatter.playerFormat.date(from: from)
        } else if let timestamp = componentsItems.first(where: {$0.name == "timestamp"})?.value,
                  let startDateTimestamp = Double(timestamp) {
            startPlayDate = Date.init(timeIntervalSince1970: startDateTimestamp)
        }
    }
    
    public func removeComponents() {
        components = nil
    }
}
