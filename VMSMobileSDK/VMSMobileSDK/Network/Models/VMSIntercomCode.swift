
import Foundation

public final class VMSIntercomCode: Decodable {
    
    public let id: Int
    public var title: String?
    public var code: String?
    public var expiredAt: Date?
    public var createdAt: Date?
    public var intercom: VMSIntercom?
    public var isExpired: Bool!
    public var willDeletedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, title, code, expiredAt, createdAt, intercom, isExpired, willDeletedAt
    }
    
    public init (from decoder: Decoder) throws {
        let container =  try decoder.container (keyedBy: CodingKeys.self)
        id = try container.decode (Int.self, forKey: .id)
        title = try? container.decode (String.self, forKey: .title)
        code = try? container.decode (String.self, forKey: .code)
        intercom = try? container.decode(VMSIntercom.self, forKey: .intercom)
        isExpired = try? container.decode(Bool.self, forKey: .isExpired)
        
        let created = try container.decode(String.self, forKey: .createdAt)
        createdAt = DateFormatter.serverUTC.date(from: (created)) ?? Date()
        let expired = try container.decode(String.self, forKey: .expiredAt)
        expiredAt = DateFormatter.serverUTC.date(from: (expired)) ?? Date()
        let willDeleted = try container.decode(String.self, forKey: .willDeletedAt)
        willDeletedAt = DateFormatter.serverUTC.date(from: (willDeleted)) ?? Date()
    }
    
    public init(id: Int, isExpired: Bool) {
        self.id = id
        self.isExpired = isExpired
    }
}
