
import Foundation

public final class VMSAnalyticCase: Decodable {
    
    public var id: Int!
    public var title: String?
    public var color: String?
    public var createdAt: Date?
    public var type: String?
    public var typePretty: String?
    public var availableEvents: [VMSAnalyticEvent]?
    
    enum CodingKeys: String, CodingKey {
        case id, title, color, createdAt, type, typePretty, availableEvents
    }
    
    public init (from decoder: Decoder) throws {
        let container =  try decoder.container (keyedBy: CodingKeys.self)
        id = try container.decode (Int.self, forKey: .id)
        title = try? container.decodeIfPresent (String.self, forKey: .title)
        color = try container.decodeIfPresent (String.self, forKey: .color)
        type = try container.decodeIfPresent (String.self, forKey: .type)
        typePretty = try container.decodeIfPresent (String.self, forKey: .typePretty)
        availableEvents = try? container.decode([VMSAnalyticEvent].self, forKey: .availableEvents)
        let created = try? container.decode(String.self, forKey: .createdAt)
        createdAt = DateFormatter.serverUTC.date(from: (created ?? "")) ?? Date()
    }
    
    public init(id: Int, title: String? = nil, color: String? = nil, type: String? = nil, typePretty: String? = nil, availableEvents: [VMSAnalyticEvent]? = nil) {
        self.id = id
        self.title = title
        self.color = color
        self.type = type
        self.typePretty = typePretty
        self.availableEvents = availableEvents
    }
}

extension VMSAnalyticCase: VMSAnalyticType {
    
    public func getId() -> Int {
        return id
    }
    
    public func typeName() -> String {
        return type ?? ""
    }
    
    public func titleName() -> String {
        return title ?? typeName()
    }
}
