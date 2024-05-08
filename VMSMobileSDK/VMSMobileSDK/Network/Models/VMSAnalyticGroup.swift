
import Foundation

public class VMSAnalyticGroup: Decodable {
    
    public var id: Int!
    public var type: String?
    public var typePretty: String?
    public var name: String?
    
    public init(id: Int, type: String? = nil, typePretty: String? = nil, name: String? = nil) {
        self.id = id
        self.type = type
        self.typePretty = typePretty
        self.name = name
    }
}
