
import Foundation

public struct VMSLoginRequest {
    
    public let login: String
    public let password: String
    public let sessionId: String?
    public let captcha: String?
    public let captchaKey: String?
    
    public init(login: String, password: String, captcha: String?, captchaKey: String?, sessionId: String?) {
        self.login = login
        self.password = password
        self.sessionId = sessionId
        self.captcha = captcha
        self.captchaKey = captchaKey
    }
}

public struct VMSLoginExternalRequest {
    
    public let loginKey: String?
    public let code: String?
    public let sessionId: String?
    
    public init(loginKey: String?, code: String?, sessionId: String?) {
        self.loginKey = loginKey
        self.code = code
        self.sessionId = sessionId
    }
}

public struct VMSChangePasswordRequest {
    
    public let new: String
    public let old: String
    public let confirmNew: String
    
    public init(new: String, old: String, confirmNew: String) {
        self.new = new
        self.old = old
        self.confirmNew = confirmNew
    }
}

public struct VMSTranslationsRequest {
    
    public let language: String
    public let revision: Int
    
    public init(language: String, revision: Int) {
        self.language = language
        self.revision = revision
    }
}

public struct VMSReportRequest {
    
    public let issueId: Int
    public let cameraId: Int
    
    public init(issueId: Int, cameraId: Int) {
        self.issueId = issueId
        self.cameraId = cameraId
    }
}

public struct VMSUpdateGroupRequest {
    
    public let groupName: String
    public let groupId: Int
    public let cameraIds: [Int]
    
    public init(groupName: String, groupId: Int, cameraIds: [Int]) {
        self.groupName = groupName
        self.groupId = groupId
        self.cameraIds = cameraIds
    }
}

public enum VMSSortDirection: String {
    /// From old to new
    case ascending = "asc"
    
    /// From new to old
    case descending = "desc"
}

/// - specific: chosen specific period from VCEventPeriod
/// - setManualy: set `from` and `to` dates respectively
public enum VMSEventTimePeriod {
    case specific(VMSEventPeriod)
    case setManualy(Date, Date)
}

public enum VMSEventPeriod: String, CaseIterable {
    case today = "today"
    case yesterday = "yesterday"
    case week = "week"
    case thirtyDays = "30days"
}

public struct VMSEventsRequest {
    public let cameraIds: [Int]
    public let types: [String]
    public let sortDirection: VMSSortDirection
    public let timePeriod: VMSEventTimePeriod?
    
    public init(
        cameraIds: [Int],
        types: [String],
        sortDirection: VMSSortDirection,
        timePeriod: VMSEventTimePeriod?
    ) {
        self.cameraIds = cameraIds
        self.types = types
        self.sortDirection = sortDirection
        self.timePeriod = timePeriod
    }
}

public struct VMSEventsAnalyticRequest {
    
    public let eventNames: [String]
    public let caseIds: [Int]
    public let cameraIds: [Int]
    public let analyticEventTypes: [String]
    public let sortDirection: VMSSortDirection
    public let timePeriod: VMSEventTimePeriod?
    
    public init(
        eventNames: [String],
        caseIds: [Int],
        cameraIds: [Int],
        types: [String],
        sortDirection: VMSSortDirection,
        timePeriod: VMSEventTimePeriod?
    ) {
        self.eventNames = eventNames
        self.caseIds = caseIds
        self.cameraIds = cameraIds
        self.analyticEventTypes = types
        self.sortDirection = sortDirection
        self.timePeriod = timePeriod
    }
}

public struct VMSIntercomFaceRecognitionRequest {
//    public let sortDirection: VMSSortDirection
    public let timePeriod: VMSEventTimePeriod?
    
    public init(
//        sortDirection: VMSSortDirection,
        timePeriod: VMSEventTimePeriod?
    ) {
//        self.sortDirection = sortDirection
        self.timePeriod = timePeriod
    }
}

public struct VMSIntercomFaceRecognitionResourceRequest {
    
    public let name: String
    public let image: Data
    let type: String
    
    public init(name: String, image: Data) {
        self.name = name
        self.image = image
        self.type = "face_resource"
    }
}

public struct VMSBridgeCreateRequest {
    public let name: String
    public let mac: String?
    public let serialNumber: String?
    
    public init?(name: String, mac: String?, serialNumber: String?) {
        self.name = name
        if mac == nil && serialNumber == nil {
            return nil
        }
        self.mac = mac
        self.serialNumber = serialNumber
    }
}

public enum VMSRewindDirection: String {
    case next
    case previous
}

public enum VMSPTZDirection: String {
    case up
    case down
    case left
    case right
    case zoomIn = "zoom-in"
    case zoomOut = "zoom-out"
}
