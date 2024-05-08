
import Foundation

public final class VMSSession: Decodable {
    
    public var id: String!
    public var userAgent: String?
    public var online: Bool!
    public var client: String?
    public var ip: String?
    public var isCurrent: Bool!
    
    public init(id: String, userAgent: String? = nil, online: Bool, client: String? = nil, ip: String? = nil, isCurrent: Bool) {
        self.id = id
        self.userAgent = userAgent
        self.online = online
        self.client = client
        self.ip = ip
        self.isCurrent = isCurrent
    }
    
}
