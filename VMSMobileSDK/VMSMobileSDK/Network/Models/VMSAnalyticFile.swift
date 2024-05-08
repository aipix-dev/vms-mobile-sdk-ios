
import Foundation

public final class VMSAnalyticFile: Decodable {
    
    public var id: Int!
    public var name: String!
    public var type: String?
    public var typePretty: String?
    public var uuid: String?
    public var url: String?
    public var body: String?
    public var createdAt: Date?
    public var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, typePretty, uuid, url, body, createdAt, updatedAt
    }
    
    public init (from decoder: Decoder) throws {
        let container =  try decoder.container (keyedBy: CodingKeys.self)
        id = try container.decode (Int.self, forKey: .id)
        name = try container.decode (String.self, forKey: .name)
        type = try? container.decodeIfPresent (String.self, forKey: .type)
        typePretty = try? container.decodeIfPresent(String.self, forKey: .typePretty)
        uuid = try? container.decodeIfPresent(String.self, forKey: .uuid)
        url = try? container.decodeIfPresent(String.self, forKey: .url)
        body = try? container.decodeIfPresent(String.self, forKey: .body)
        
        let created = try container.decode(String.self, forKey: .createdAt)
        createdAt = DateFormatter.serverUTC.date(from: (created)) ?? Date()
        let updated = try container.decode(String.self, forKey: .updatedAt)
        updatedAt = DateFormatter.serverUTC.date(from: (updated)) ?? Date()
    }
    
    public init(id: Int, name: String, url: String? = nil, type: String? = nil, typePretty: String? = nil, uuid: String? = nil, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.url = url
        self.type = type
        self.typePretty = typePretty
        self.uuid = uuid
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension VMSAnalyticFile {
    
    func editPreviewUrl(baseUrl: String) {
        if let url, url.starts(with: "/") {
            self.url = baseUrl + url
        }
    }
}

extension VMSAnalyticFile: VMSAnalyticType {
    public func getId() -> Int {
        return id
    }
    
    public func typeName() -> String {
        return type ?? ""
    }
    
    public func titleName() -> String {
        return name ?? ""
    }
}
