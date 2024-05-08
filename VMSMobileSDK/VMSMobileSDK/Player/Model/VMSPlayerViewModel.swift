
import Foundation

public protocol VMSPlayerApi: CameraApi, PlayerApi, CameraEventsApi {}

protocol VMSPlayerViewModelDelegate: AnyObject {
    func qualityChanged()
    func userReloaded()
    func liveStreamDidLoaded(url: String)
    func liveStreamDidLoadedWithError(_ error: String)
    func archiveStreamDidLoadedWithError(_ error: String)
    func markCreated(from: Date)
    func markHandlerError(_ error: String)
    func markEdited(id: Int, name: String, from: Date)
    func markRewinded(mark: VMSEvent?, direction: VMSRewindDirection)
    func markOptionChanged()
    func playerTypeChanged()
    func getAvailableMarkTypes() -> [VMSEventType]
    func playerErrorStateChanged()
}

public final class VMSPlayerViewModel {
    
    public var camera: VMSCamera
    public var groupCameras: [VMSCamera]
    
    public var currentQuality: VMSStream.QualityType = .high
    
    public var currentStream: VMSStream? {
        return currentQuality == .high ? camera.highStream() : camera.lowStream()
    }
    
    public var currentStreamCodecType: VMSStream.VideoCodec {
        return currentQuality == .high ? currentStream?.videoCodec ?? .h265 : currentStream?.videoCodec ?? .h265
    }
    
    public var nullStreams: VMSStream? { return camera.nullStreams() }
    public var hasSound: Bool { return currentStream?.hasSound ?? false }
    public var hasPtz: Bool { return camera.hasPTZ ?? false }
    
    public var cameraEvents: [VMSEvent] = []
    
    public var user: VMSUser!
    public var playerApi: VMSPlayerApi
    public var translations: VMSPlayerTranslations
    
    public var currentEventOption: VMSVideoEventOptions = .all {
        didSet {
            if oldValue != currentEventOption {
                self.delegate?.markOptionChanged()
            }
        }
    }
    
    public var playerType: VMSPlayerOptions.VMSPlayerType
    public var isSoundOn: Bool = false
    public var askForNet: Bool = false
        
    public var options: VMSPlayerOptions
        
    weak var delegate: VMSPlayerViewModelDelegate?
    
    public enum PlayerErrorState {
        case normal
        case liveRestricted
        case archiveRestricted
        case streamError
        case archiveError
        case archiveOutOfRange
        case empty
        case inactive
        case initial
        case unknown
        case blocked
    }
    
    public var playerErrorState = PlayerErrorState.normal {
        didSet {
            delegate?.playerErrorStateChanged()
        }
    }
    
    public init(
        camera: VMSCamera,
        groupCameras: [VMSCamera]?,
        user: VMSUser,
        translations: VMSPlayerTranslations,
        playerApi: VMSPlayerApi,
        options: VMSPlayerOptions,
        currentEventOption: VMSVideoEventOptions = .all
    ) {
        self.camera = camera
        self.groupCameras = groupCameras ?? []
        self.user = user
        self.translations = translations
        self.playerApi = playerApi
        self.options = options
        self.playerType = options.defaultPlayerType
        self.currentQuality = options.defaultQuality
        self.currentEventOption = currentEventOption
        self.isSoundOn = options.allowSoundOnStart
        checkQuality()
    }
    
    // MARK: - PUBLIC
    
    public func setPlayerType(_ type: VMSPlayerOptions.VMSPlayerType) {
        if self.playerType == type {
            // Player type hasn't been changed, do nothing in this case
            return
        }
//        self.playerType = type
//        self.delegate?.playerTypeChanged()
    }
//        public func getPlayerType(isLive: Bool) -> VMSPlayerOptions.VMSPlayerType {
    public func getPlayerType(isLive: Bool) -> VMSPlayerOptions.VMSPlayerType {
//        return isLive ? self.playerType : .hls
        return isLive
            ? currentStreamCodecType == .h264 
                ? .rtspH264
                : .rtspH265
            : camera.highStream()?.videoCodec == .h264 
                ? .rtspH264
                : .rtspH265
    }
    
    public func checkQuality() {
        let old = currentQuality
        var new = old
        if camera.highStream() == nil && old == .high {
            new = .low
        } else if camera.lowStream() == nil && old == .low {
            new = .high
        }
        if old != new {
            currentQuality = new
            delegate?.qualityChanged()
        }
    }
    
    public func resignApi() {
        playerApi.cancelStreamRequest(by: camera.id)
        playerApi.cancelArchiveRequest(by: camera.id)
        playerApi.cancelCameraInfoRequest(with: camera.id)
    }
    
    public func setDefaultQiality(quality: VMSStream.QualityType) {
        self.options = VMSPlayerOptions(
            language: options.language,
            allowVibration: options.allowVibration,
            allowSoundOnStart: isSoundOn,
            markTypes: options.markTypes,
            videoRates: options.videoRates,
            onlyScreenshotMode: options.onlyScreenshotMode,
            defaultQuality: quality
        )
    }
    
    public func needShowAskForNetDialogue() -> Bool {
        return options.askForNet && playerApi.isNoWiFiConnected() && !askForNet
    }
    
    // MARK: Streams
    
    public func getCameraStream() {
        playerApi.getStream(by: camera.id, quality: currentQuality) { [weak self] response in
            guard let self = self else { return }
            switch response {
            case .success(let streamResponse):
                if streamResponse.url.isEmpty {
                    self.delegate?.liveStreamDidLoadedWithError(self.translations.translate(.StreamNotAvailable))
                    return
                }
                self.delegate?.liveStreamDidLoaded(url: streamResponse.url)
            case .failure(_):
                switch self.camera.status {
                case .inactive:
                    self.delegate?.liveStreamDidLoadedWithError(self.translations.translate(.ErrCameraUnavailalbe))
                case .initial:
                    self.delegate?.liveStreamDidLoadedWithError(self.translations.translate(.ErrCameraInitLong))
                case .empty:
                    self.delegate?.liveStreamDidLoadedWithError(self.translations.translate(.ErrCameraStreamsUnavailable))
                default: 
                    self.delegate?.liveStreamDidLoadedWithError(self.translations.translate(.ErrStreamUnavailable))
                }
            }
        }
    }
    
    public func getCameraArchive(_ start: Date, success: ((String, Date) -> Void)?) {
        playerApi.getArchive(by: camera.id, start: start) { [weak self] response in
            guard let self = self else { return }
            switch response {
            case .success(let urlResponse):
                if urlResponse.url.isEmpty {
                    self.delegate?.archiveStreamDidLoadedWithError(self.translations.translate(.ErrCantLoadArchive))
                    return
                }
                success?(urlResponse.url, start)
            case .failure(let error):
                if error.type == .incorrectData(nil) {
                    self.delegate?.archiveStreamDidLoadedWithError(error.message ?? self.translations.translate(.ErrCantLoadArchive))
                } else {
                    self.delegate?.archiveStreamDidLoadedWithError(self.translations.translate(.ErrCantLoadArchive))
                }
            }
        }
    }
    
    public func getCameraInfo(success:((VMSCamera) -> Void)?, failure: ((String) -> Void)?) {
        playerApi.getCamera(with: camera.id) { [weak self] response in
            guard let self = self else { return }
            switch response {
            case .success(let cam):
                self.camera = cam
                self.checkQuality()
                success?(cam)
            case .failure(_):
                failure?(self.translations.translate(.ErrCommonShort))
            }
        }
    }
    
    // MARK: - Marks
    
    public func setMarksFilter(by types: [VMSEventType]) {
        if types.isEmpty {
            currentEventOption = .none
        } else if types.count == options.markTypes.count {
            currentEventOption = .all
        } else {
            currentEventOption = .types(types.map { $0.typeName() })
        }
    }
    
    public func getCameraEvents(from: Date, to: Date, success: (([VMSEvent]) -> Void)?) {
        if currentEventOption == .none { return }
        var types: [String] = []
        switch currentEventOption {
        case .all:
            types = delegate?.getAvailableMarkTypes().map{$0.name} ?? []
        default:
            types = currentEventOption.value(fromTranslations: translations)
        }
        
        playerApi.getCameraEvents(with: camera.id, from: from, to: to, types: types) { [weak self] response in
            guard let self = self else {return}
            switch response {
            case .success(let events):
                self.cameraEvents = events
                success?(events)
            case .failure(_):
                break
            }
        }
    }
    
    public func createMark(name: String, from: Date) {
        playerApi.createEvent(cameraId: camera.id, eventName: name, from: from) { [weak self] response in
            switch response {
            case .success(_):
                self?.delegate?.markCreated(from: from)
            case .failure(_):
                self?.delegate?.markHandlerError(self?.translations.translate(.MarkCreateFailed) ?? "")
            }
        }
    }
    
    public func editMark(markId: Int, name: String, from: Date) {
        playerApi.updateEvent(with: markId, cameraId: camera.id, eventName: name, from: from) { [weak self] response in
            switch response {
            case .success(_):
                self?.delegate?.markEdited(id: markId, name: name, from: from)
            case .failure(_):
                self?.delegate?.markHandlerError(self?.translations.translate(.MarkUpdateFailed) ?? "")
            }
        }
    }
    
    public func rewindMark(date: Date, direction: VMSRewindDirection, transform: CGFloat, speed: Double) {
        var currentTypes: [String] = []
        switch currentEventOption {
        case .types( let types):
            currentTypes = types
        default:
            currentTypes = delegate?.getAvailableMarkTypes().compactMap { $0.name } ?? []
        }
        
        let interval: Double = 35.0 * speed
        guard let dateWith5Sec = Calendar.current.date(byAdding: .second, value: Int((direction == .next ? interval : -interval) / transform), to: date) else {return}
        
        playerApi.getNearestEvent(with: camera.id, from: dateWith5Sec, types: currentTypes, direction: direction) { [weak self] response in
            guard let self = self else { return }
            switch response {
            case .success(let mark):
                self.delegate?.markRewinded(mark: mark.mark, direction: direction)
            case .failure(_):
                self.delegate?.markHandlerError(direction == .next ? self.translations.translate(.NoNewerMarks) : self.translations.translate(.NoOlderMarks))
            }
        }
    }
    
    // MARK: Permissions
    
    public func hasPermission(_ permission: VMSPermission.PermissionType) -> Bool {
        if let user = self.user, user.hasPermission(permission) {
            return true
        }
        return false
    }
    
    public func hasEventsPermissions() -> Bool {
        if hasPermission(.MarksIndex) || hasAnalyticPermission() || hasPermission(.CameraEventsIndex) {
            return true
        }
        return false
    }
    
    public func hasAnalyticPermission() -> Bool {
        return hasPermission(.Analytic) || hasPermission(.AnalyticCasesIndex)
    }
    
    // MARK: Camera Group
    
    public func canSwipeCameras() -> Bool {
        return groupCameras.count != 0
    }
    
    public func getCameraIndexInGroup() -> Int? {
        return groupCameras.lastIndex(where: { (cam) -> Bool in
            return cam.id == camera.id
        })
    }
    
    // MARK: - Player Error State
    
    public func setNewPlayerState(cameraStatus: VMSCameraStatusType? = nil, customError: PlayerErrorState? = nil) {
        if let custom = customError {
            playerErrorState = custom
        } else if let cameraError = cameraStatus {
            switch cameraError {
            case .active:
                playerErrorState = .normal
            case .empty:
                playerErrorState = .empty
            case .inactive:
                playerErrorState = .inactive
            case .initial:
                playerErrorState = .initial
            case .partial:
                playerErrorState = .normal
            }
        }
    }
    
    public func getPlayerStateError() -> (String?, String?) {
        let defaultDescription = translate(.InactiveCameraMessage)
        switch playerErrorState {
        case .normal:
            return (nil, nil)
        case .liveRestricted:
            return (translations.translate(.ErrLiveRestrictedShort), defaultDescription)
        case .archiveRestricted:
            return (translations.translate(.ErrArchiveRestricted), defaultDescription)
        case .streamError:
            return (translations.translate(.ErrStreamUnavailable), defaultDescription)
        case .archiveError:
            return (translations.translate(.ErrArchiveUnavailable), defaultDescription)
        case .archiveOutOfRange:
            return (translations.translate(.ErrArchiveUnavailable), translations.translate(.ItTakesTimeToGenerateArchive))
        case .empty:
            return (translations.translate(.ErrCameraStreamsUnavailable), defaultDescription)
        case .inactive:
            return (translations.translate(.InactiveCameraTitle), defaultDescription)
        case .initial:
            return (translations.translate(.ErrCameraInit), defaultDescription)
        case .unknown:
            return (translations.translate(.ErrCommonShort), defaultDescription)
        case .blocked:
            return (translations.translate(.CameraBlocked), defaultDescription)
        }
    }
    
    public func getSnackPlayerStateError() -> String {
        let currentError = getPlayerStateError().0 ?? ""
        if currentError.isEmpty {
            return translations.translate(.ErrCommonShort)
        }
        switch playerErrorState {
        case .inactive:
            return  "\(translations.translate(.ErrInThisMoment)) \(currentError.lowercased())"
        case .normal:
            return ""
        default:
            return currentError
        }
    }
    
    // Translation
    
    public func translate(_ key: VMSPlayerTranslations.DictKeys) -> String {
        return translations.translate(key)
    }
    
    public func getTimeComponentTranslation(component: Calendar.Component) -> String {
        if component == .day {
            return translate(.Day)
        } else if component == .hour {
            return translate(.Hour)
        } else if component == .minute {
            return translate(.Minute)
        }
        return translate(.Seconds)
    }
}
