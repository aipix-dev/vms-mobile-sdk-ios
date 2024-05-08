

import UIKit

class VideoPlayerRTSPNative: NSObject, VideoPlayer, RTSPPlayerH264Delegate {
    private var videoView = UIView()
    private var videoLayer: AVSampleBufferDisplayLayer?
    private var video: RTSPPlayerH264?
    private var videoQueue: DispatchWorkItem?
    
    public weak var delegate: VideoPlayerDelegate?
    
    private var startPlayDate: Date?
    private var currentPlayDate: Date?
    private var canPlaySound: Bool = false
    private var soundOn: Bool = false {
        didSet {
            video?.setSoundOnOff(soundOn)
        }
    }
    
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
    
    public var videoRatio: CGFloat?
    private var currentSpeed: Double = 1.0
    private var components: URLComponents?
    private var retryAttemps: Int = 0
    
    deinit {
        resignPlayer()
        removeComponents()
        videoLayer?.flushAndRemoveImage()
        videoLayer?.removeFromSuperlayer()
        videoLayer = nil
        print("RTSP Player: DEINIT")
    }
    
    // MARK: - PUBLIC
    
    public var isGravityResizeAspect: Bool = true {
        didSet {
            videoView.layer.contentsGravity = isGravityResizeAspect ? .resizeAspect : .resize
            videoLayer?.videoGravity = isGravityResizeAspect ? .resizeAspect : .resize
        }
    }
    
    func setup(to view: UIView) {
        self.videoView.contentMode = .scaleAspectFit
        view.addSubview(self.videoView)
        self.videoView.translatesAutoresizingMaskIntoConstraints = false
        self.videoView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        self.videoView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        self.videoView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        self.videoView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        
        setupVideoLayer()
    }
    
    private func setupVideoLayer() {
        videoLayer = AVSampleBufferDisplayLayer()
        videoLayer?.frame = self.videoView.frame
        videoLayer?.bounds = self.videoView.bounds;
        videoLayer?.videoGravity = AVLayerVideoGravity.resizeAspect
        
        var controlTimebase: CMTimebase?
        CMTimebaseCreateWithSourceClock( allocator: nil, sourceClock: CMClockGetHostTimeClock(), timebaseOut: &controlTimebase );
        
        
        videoLayer?.controlTimebase = controlTimebase;
        
        // Set the timebase to the initial pts here
        if let controlTimebase = videoLayer?.controlTimebase {
            CMTimebaseSetTime(controlTimebase, time: CMTime.zero)
            CMTimebaseSetRate(controlTimebase, rate: 1.0);
        }
        
        guard let videoLayer = videoLayer else { return }
        self.videoView.layer.addSublayer(videoLayer)
    }
    
    private func resetVideoLayerOnView() {
        videoLayer?.flush()
        videoLayer?.stopRequestingMediaData()
        videoLayer?.removeFromSuperlayer()
        
        setupVideoLayer()
    }
    
    func remove() {
        self.videoView.removeFromSuperview()
    }
    
    func viewDidAppear(in view: UIView) {
        isGravityResizeAspect = true
    }
    
    internal func updateFrame(to bounds: CGRect) {
        resetVideoLayerOnView()
    }
    
    public func getGravityResizeAspect() -> Bool {
        return isGravityResizeAspect
    }
    
    public func setGravityResizeAspect(_ value: Bool) {
        isGravityResizeAspect = value
    }
    
    public func getVideoRatio() -> CGFloat {
        return videoRatio ?? 1
    }
    
    public func setVolume(_ volume: Float) {
        soundOn = volume == 1 ? true : false
    }
    
    func playerHasSound() -> Bool {
        return canPlaySound
    }
    
    public func getPlayerScreenshot() {
        self.video?.getScreenshot()
    }
    
    public func endPlayer() {
        currentPlayDate = nil
        startPlayDate = nil
        resignPlayer()
    }
    
    public func playerDate() -> Date? {
        guard let currentPlayDate = currentPlayDate else {
            return startPlayDate
        }
        return currentPlayDate
    }
    
    func play(hasSound: Bool, soundOn: Bool) {
        self.soundOn = soundOn
        self.canPlaySound = false
    }
    
    func pause(soundOn: Bool) {
        self.soundOn = false
        self.startPlayDate = self.playerDate()
        self.resignPlayer()
    }
    
    public func playVideo(atSpeed speed: Double, fromDate date: Date) {
        
        /**
         Now we ignore the date parameter for all across resume playng, since we get the timestamp in the URL to play the archive.
         */
        
        guard var comps = components, let url = comps.url else { return }
        resignPlayer()
        
        currentSpeed = speed
        
        print("RTSP Player: inner date \(date)")
        
        let queryNamesToRemove = Set(["timestamp", "speed", "time"])
        
        comps.queryItems?.removeAll { query in
            return queryNamesToRemove.contains(query.name)
        }
        
        if let timeStamp = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "timestamp" })?.value {
            let date = Date(timeIntervalSince1970: Double(timeStamp) ?? 0)
            let time = DateFormatter.playerFormat.string(from: date)
            comps.queryItems?.append(URLQueryItem(name: "time", value: time))
            print("RTSP Player: url date \(date)")
        } else if URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "time" })?.value != nil {
            let time = DateFormatter.playerFormat.string(from: date)
            comps.queryItems?.append(URLQueryItem(name: "time", value: time))
            print("RTSP Player: url date \(date)")
        }
        
        comps.queryItems?.append(URLQueryItem(name: "speed", value: speed.cleanString()))
        self.components = comps
        
        guard let newUrl = comps.url, let queryItems = comps.queryItems, !queryItems.isEmpty else { return }
        playUrl(newUrl)
    }
    
    private func setPlayStatus(_ newStatus: Bool) {
        if !isPlaying, newStatus {
            delegate?.playerStartedToPlay()
        }
    }
    
    public func playUrl(_ url: URL) {
        resignPlayer()
        print("RTSP Player URL:\n\(url.absoluteString)")
        let videoQueueItem = DispatchWorkItem.init(qos: .userInteractive, block: {
            self.startPlayer(url)
        })
        videoQueue = videoQueueItem
        
        DispatchQueue.global(qos: .userInitiated).async(execute: videoQueueItem)
    }
    
    private func startPlayer(_ url: URL) {
        do {
            videoLayer?.flushAndRemoveImage()
            self.canPlaySound = false
            try self.video = RTSPPlayerH264(videoUrl: url.absoluteString,
                                            withAudio: true,
                                            soundIsOn: self.soundOn,
                                            speed: self.convertSpeed(speed: self.currentSpeed),
                                            delegate: self)
        } catch {}
        
        if self.startPlayDate == nil {
            self.startPlayDate = Date()
        }
        self.video?.start()
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
    
    public func resignPlayer() {
        self.isPlaying = false
        self.video?.setSoundOnOff(false)
        self.video?.stop()
        self.video = nil
        videoQueue?.cancel()
        videoQueue = nil
    }
    
    private func convertSpeed(speed: Double) -> RTSPPlaybackSpeed {
        switch speed {
        case 0.5:
            return RTSPPlaybackSpeed.speedSlow
        case 2:
            return RTSPPlaybackSpeed.speed2x
        case 4:
            return RTSPPlaybackSpeed.speed4x
        case 8:
            return RTSPPlaybackSpeed.speed8x
        default:
            return RTSPPlaybackSpeed.speed1x
        }
    }
    
    private func cleanString(from value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 { // 1.0, 5.0, etc
            return String(Int(value))
        }
        return String(value)
    }
    
    // MARK: - RTSP Player Delegate
    
    func rtspPlayerH264StateChanged(_ state: RTSPPlayerState) {
        DispatchQueue.main.async {
            switch state {
            case .isStarting:
                print("RTSP Player State Is: Starting")
            case .isReadyToPlay:
                print("RTSP Player State Is: Ready to Play")
                return
            case .isPlaying:
                self.delegate?.playerItemDidReadyToPlay()
                print("RTSP Player State Is: Playing")
            case .isHasSound:
                self.canPlaySound = true
                self.delegate?.playerHasSound(hasSound: self.canPlaySound)
                print("RTSP Player State Is: Has sound")
            case .isNoSound:
                self.canPlaySound = false
                self.delegate?.playerHasSound(hasSound: self.canPlaySound)
                print("RTSP Player State Is: No sound")
            case .isStopped:
                print("RTSP Player State Is: Stopped")
            @unknown default:
                break
            }
        }
    }
    
    func rtspPlayerH264SocketStateChanged(_ state: SocketState) {
        DispatchQueue.main.async {
            switch state {
            case .notConnected:
                print("RTSP Player Socket State: Is Not Connected")
            case .connecting:
                print("RTSP Player Socket State: Is Connecting")
            case .connected:
                print("RTSP Player Socket State: Is Connected")
            case .doOption:
                print("RTSP Player Socket State: Is Do Option")
            case .doDescribe:
                print("RTSP Player Socket State: Is Do Describe")
            case .doSetupVideo:
                print("RTSP Player Socket State: Is Do Setup Video")
            case .doSetupAudio:
                print("RTSP Player Socket State: Is Do Setup Audio")
            case .doPlay:
                print("RTSP Player Socket State: Is Do Play")
            case .doTeardown:
                print("RTSP Player Socket State: Is Do Teardown")
            case .playing:
                print("RTSP Player Socket State: Is Playing")
            case .disconnected:
                print("RTSP Player Socket State: Is Disconnected")
            @unknown default:
                break
            }
        }
    }
    
    func rtspPlayerH264Error(_ playbackError: RTSPPlaybackError, error: Error?) {
        DispatchQueue.main.async {
            switch playbackError {
            case .playerUnknownVideoFormat:
                print("RTSP Player: Unknown Video Format")
                self.delegate?.playerDidFail(message: nil)
            case .playerUnknownAudioFormat:
                print("RTSP Player: Unknown Audio Format");
                return
            case .playerCorruptPacketsError:
//                print("RTSP Player Corrupt Packets Error")
                return
            case .playerContentTimeoutError:
                print("RTSP Player: Timeout Error: \(error?.localizedDescription ?? "")");
            case .playerEmptyFramesError:
//                print("RTSP Player: Empty Frames Error");
                
                //                self.retryAttemps += 1
                //
                //                if self.retryAttemps > 2 {
                //                    self.endPlayer()
                //                    self.delegate?.playerDidFail(message: nil)
                //                    self.retryAttemps = 0
                //                    print("RTSP Player: RETRY ATTEMPS REACHED: \(error?.localizedDescription ?? "")")
                //                    return
                //                }
                //                self.endPlayer()
                //                self.delegate?.playerNeedToRestart()
                return
            @unknown default:
                break
            }
        }
    }
    
    func rtspPlayerH264ConnectionError(_ connectionError: RTSPConnectionError, error: Error?) {
        DispatchQueue.main.async {
            switch connectionError {
            case .playerUnauthorizedError:
                print("RTSP Player: Unauthorized Error")
            case .playerBrokenLinkError:
                print("RTSP Player: Broken Link Error")
            case .playerConnectResponseError:
                print("RTSP Player: ConnectResponseError")
            case .playerConnectTimeoutError:
                print("RTSP Player: Connect Timeout Error")
            case .playerNeedConnectToNewUrlError:
                print("RTSP Player: Need Connect To New Url Error")
                return
            case .playerNoContentError:
                print("RTSP Player: No Content Error HTTP 204")
                self.videoLayer?.flushAndRemoveImage()
                self.delegate?.playerDidFail(message: "HTTP 204")
                return
            case .playerHasUnknownError:
                print("RTSP Player: Has Unknown Error")
            case .playerNeedReconnect:
                print("RTSP Player: Need Reconnect Has Unknown Response")
                self.videoLayer?.flushAndRemoveImage()
                return;
            @unknown default:
                break
            }
            self.videoLayer?.flushAndRemoveImage()
            self.delegate?.playerDidFail(message: nil)
        }
    }
    
    func rtspPlayerH264HasSampleBuffer(_ sampleBuffer: CMSampleBuffer?) {
        guard let sampleBuffer = sampleBuffer else { return }
        if let dimensions = sampleBuffer.formatDescription?.dimensions, videoRatio == nil {
            setVideoRatio(dimensions)
        }
        videoLayer?.enqueue(sampleBuffer)
    }
    
    private func setVideoRatio(_ dimensions: CMVideoDimensions) {
        if dimensions.width != 0, dimensions.height != 0 {
            videoRatio = CGFloat(dimensions.width / dimensions.height)
        }
    }
    
    func rtspPlayerH264CurrentPlaybackDate(_ date: Date?) {
        self.currentPlayDate = date
    }
    
    func rtspPlayerH264ScreenshotReady(_ screenshot: UIImage?) {
        DispatchQueue.main.async {
            self.delegate?.playerHasScreenshot(screenshot: screenshot)
        }
    }
    
}
