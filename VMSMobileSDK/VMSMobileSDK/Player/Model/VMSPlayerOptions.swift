
import Foundation

public struct VMSPlayerOptions {
    
    public enum VMSPlayerType: String, CaseIterable {
        case rtspH264
        case rtspH265
//        case hls
    }
    
    let language: String
    let allowVibration: Bool
    let allowSoundOnStart: Bool
    let markTypes: [VMSEventType]
    let videoRates: [Double]
    let onlyScreenshotMode: Bool
    let defaultPlayerType: VMSPlayerType
    let askForNet: Bool
    let defaultQuality: VMSStream.QualityType
    
    /// Initialize options with which player will work
    /// 
    /// - parameter language: current language. Available options can be received from `VMSBasicStatic` object
    ///
    /// - parameter allowVibration: default is true
    ///
    /// - parameter allowSoundOnStart: indicates if allow player to start audio if camera has sound right after player loaded. Default is true
    ///
    /// - parameter markTypes: array of available mark types. Can be received from `VMSStatic` object
    ///
    /// - parameter videoRates: array of available speed rates. Can be received from `VMSStatic` object
    ///
    /// - parameter onlyScreenshotMode: set true if you want no other player functionality available except to make screenshot on live
    ///
    /// - parameter defaultPlayerType: default stream type that will be loaded at first place for a camera if possible. HLS type by default
    ///
    /// - parameter askForNet: set true if you want no ask player is no WIFI connection
    ///
    /// - parameter defaultQuality: default stream quality that will be loaded at first place for a camera if possible. High quality by default

    public init(
        language: String,
        allowVibration: Bool? = nil,
        allowSoundOnStart: Bool? = nil,
        markTypes: [VMSEventType],
        videoRates: [Double],
        onlyScreenshotMode: Bool = false,
        defaultPlayerType: VMSPlayerType = .rtspH265,
        askForNet: Bool = false,
        defaultQuality: VMSStream.QualityType = .high
    ) {
        self.language = language
        self.allowVibration = allowVibration ?? true
        self.allowSoundOnStart = allowSoundOnStart ?? true
        self.videoRates = videoRates
        self.markTypes = markTypes
        self.onlyScreenshotMode = onlyScreenshotMode
        self.defaultPlayerType = defaultPlayerType
        self.askForNet = askForNet
        self.defaultQuality = defaultQuality
    }
}
