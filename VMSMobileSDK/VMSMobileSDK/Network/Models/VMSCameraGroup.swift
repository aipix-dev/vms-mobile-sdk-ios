
import Foundation

public final class VMSCameraGroup: Decodable {
    
    public let id: Int
    public var items: [VMSCamera]!
    public var name: String?
    public var itemsCount: Int?
    public var previews: [VMSCameraPreview]?
    
    public init(id: Int, cameras: [VMSCamera]) {
        self.id = id
        self.items = cameras
    }
    
    public init(id: Int, name: String?) {
        self.id = id
        self.name = name
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case id
        case items
        case itemsCount
        case previews
    }
}
