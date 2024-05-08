
import Foundation

public final class VMSStatic: Decodable {
    
    public var cameraIssues: [VMSCameraIssue]?
    public var videoRates: [Double]?
    public var markTypes: [VMSEventType]?
    public var systemEvents: [VMSEventType]?
    public var analyticEvents: [VMSEventType]?
    public var analyticTypes: [VMSEventType]?
    
    public init(
        cameraIssues: [VMSCameraIssue]? = nil,
        videoRates: [Double]? = nil,
        markTypes: [VMSEventType]? = nil,
        systemEvents: [VMSEventType]? = nil,
        analyticEvents: [VMSEventType]? = nil,
        analyticTypes: [VMSEventType]? = nil
    ) {
        self.cameraIssues = cameraIssues
        self.videoRates = videoRates
        self.markTypes = markTypes
        self.systemEvents = systemEvents
        self.analyticEvents = analyticEvents
        self.analyticTypes = analyticTypes
    }
}

public final class VMSBasicStatic: Decodable {
    
    public var isCaptchaAvailable: Bool?
    public var isExternalAuthEnabled: Bool?
    public var availableLocales: [String]
    public var version: String?
    
    public init(isCaptchaAvailable: Bool? = nil, isExternalAuthEnabled: Bool? = nil, version: String? = nil, availableLocales: [String]) {
        self.isCaptchaAvailable = isCaptchaAvailable
        self.isExternalAuthEnabled = isExternalAuthEnabled
        self.version = version
        self.availableLocales = availableLocales
    }
}

public final class VMSCameraIssue: Decodable {
    
    public let id: Int
    public var title: String?
    
    public init(id: Int, title: String? = nil) {
        self.id = id
        self.title = title
    }
}
