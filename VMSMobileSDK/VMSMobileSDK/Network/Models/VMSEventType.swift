
import Foundation

public final class VMSEventType: Codable {
    
    public var name: String!
    public var description: String?
    public var title: String?
    public var color: String?
    public var analyticType: String?
    
    /// Default user's mark
    public static let defaultType: String = "mark"
    
    public init(name: String, description: String? = nil, title: String? = nil, color: String? = nil, analyticType: String? = nil) {
        self.name = name
        self.description = description
        self.title = title
        self.color = color
        self.analyticType = analyticType
    }
}

extension VMSEventType: VMSAnalyticType {
    
    public func getId() -> Int {
        return 0
    }
    
    public func typeName() -> String {
        return name
    }
    
    public func titleName() -> String {
        return description ?? title ?? ""
    }
}
