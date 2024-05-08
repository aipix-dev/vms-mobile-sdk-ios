
import Foundation

public protocol VMSAnalyticType {
    func getId() -> Int
    func typeName() -> String
    func titleName() -> String
}

public final class VMSAnalyticEvent: Decodable {
    
    public var id: Int!
    public var name: String?
    public var color: String?
    public var type: String?
    public var typePretty: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, color
        case type = "analytic_type"
        case typePretty = "description"
    }
    
    public init(id: Int, name: String? = nil, color: String? = nil, type: String? = nil, typePretty: String? = nil) {
        self.id = id
        self.name = name
        self.color = color
        self.type = type
        self.typePretty = typePretty
    }
}

extension VMSAnalyticEvent: VMSAnalyticType {
    
    public func getId() -> Int {
        return id
    }
    
    public func typeName() -> String {
        return name ?? ""
    }
    
    public func titleName() -> String {
        return typePretty ?? ""
    }
}
