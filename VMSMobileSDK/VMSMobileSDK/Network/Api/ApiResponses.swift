
import Foundation

public struct VMSSessionResponse: Decodable {
    
    /// Indicates how many sessions can be simultaniously for this user
    public var sessionsLimit: Int?
    public var sessions: [VMSSession]?
    
    /// If there is login key istead of using `login` method use `logiWithExternal` method.
    /// In this case no `code` parameter needed for this request.
    public var loginKey: String?
    
    /// If there is a captcha required for login, this property indicates how long this capture will be valid.
    /// After this time user will have to enter another captcha
    public var captchaWillRequireIn: Int?
    
    enum CodingKeys: String, CodingKey {
        case sessionsLimit = "sessions_limit"
        case sessions
        case loginKey = "key"
        case captchaWillRequireIn = "captcha_will_required_in"
    }
}

public struct VMSUserResponse: Decodable {
    
    public let user: VMSUser
    public let accessToken: String
}

public struct VMSUrlStringResponse: Decodable {
    public let url: String
}

public struct VMSCameraPreviewResponse: Decodable {
    public let preview: String
}

public struct VMSTypeGroupResponse: Decodable {
    public let type: VMSGroupSyncType
}

public struct VMSRewindEventResponse: Decodable {
    public let mark: VMSEvent?
}

public enum VMSGroupSyncType: String, Decodable {
    case sync
    case async
}

public struct VMSSocketResponse: Decodable {
    public let wsUrl: String
    public let appKey: String
}
