
import Foundation

public final class VMSIntercom: Decodable {
    
    public enum AnswerDevicesType: String, Decodable {
        case current = "is_enabled"
        case landline = "is_landline_sip_line_available"
        case analog = "is_analog_line_available"
    }
    
    public enum IntercomStatus: String, Decodable {
        case keyConfirmed
        case confirmed
    }
    
    public let id: Int
    public var title: String?
    public var department: Int?
    public var address: String?
    public var isEnabled: Bool?
    public var camera: VMSIntercomCamera?
    public var status: IntercomStatus?
    public var timetable: VMSTimetable?
    public var isOnline: Bool?
    public var isAnalyticAvailable: Bool?
    public var availableAnswerDevices: [AnswerDevicesType]?
    public var isLandlineSipLineAvailable: Bool?
    public var isAnalogLineAvailable: Bool?
    public var isOpenDoorCode: Bool!
    public var isOpenDoorFace: Bool!
    public var isOpenDoorApp: Bool!
    
    public init(id: Int, isEnabled: Bool) {
        self.id = id
        self.isEnabled = isEnabled
    }
}

public final class VMSActivationCode: Decodable {
    
    public var code: String!
    public var expireInSeconds: Int!
    
    public init(code: String, expireInSeconds: Int) {
        self.code = code
        self.expireInSeconds = expireInSeconds
    }
}

public final class VMSIntercomCamera: Decodable {
    
    public enum StatusType: String, Decodable {
        case active
        case inactive
        case partial
        case empty
        case initial
    }

    public enum UserStatus: String, Decodable {
        case active
        case blocked
    }
    
    public let id: Int
    public var groupId: Int!
    public var status: StatusType?
    public var startAt: String?
    public var createdAt: String?
    public var prettyName: String?
    public var isBridge: Bool?
    public var isFavorite: Bool?
    public var isRestrictedLive: Bool?
    public var isRestrictedArchive: Bool?
    public var userStatus: UserStatus?
    public var name: String!
    
    public init(id: Int, groupId: Int, status: StatusType? = nil, startAt: String? = nil, createdAt: String? = nil, prettyName: String? = nil, isBridge: Bool? = nil, isFavorite: Bool? = nil, isRestrictedLive: Bool? = nil, isRestrictedArchive: Bool? = nil, userStatus: UserStatus? = nil, name: String) {
        self.id = id
        self.groupId = groupId
        self.status = status
        self.startAt = startAt
        self.createdAt = createdAt
        self.prettyName = prettyName
        self.isBridge = isBridge
        self.isFavorite = isFavorite
        self.isRestrictedLive = isRestrictedLive
        self.isRestrictedArchive = isRestrictedArchive
        self.userStatus = userStatus
        self.name = name
    }
}



