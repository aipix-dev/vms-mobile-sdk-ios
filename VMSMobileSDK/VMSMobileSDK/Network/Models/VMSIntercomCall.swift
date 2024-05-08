
import Foundation

public final class VMSIntercomCall: Decodable {
    
    public enum VMSCallStatus: String, Codable {
        case missed
        case ring
        case ended
        case answered
    }
    
    public let id: Int
    public var status: VMSCallStatus?
    public var startedAt: String?
    public var createdAt: String?
    public var endedAt: String?
    public var intercom: VMSIntercom?
    public var markType: String?
    
    public init(id: Int, status: VMSCallStatus? = nil, startedAt: String? = nil, createdAt: String? = nil, endedAt: String? = nil, intercom: VMSIntercom? = nil, markType: String?) {
        self.id = id
        self.status = status
        self.startedAt = startedAt
        self.createdAt = createdAt
        self.endedAt = endedAt
        self.intercom = intercom
        self.markType = markType
    }
}
