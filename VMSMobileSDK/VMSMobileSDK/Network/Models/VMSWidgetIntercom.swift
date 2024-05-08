
import Foundation

public final class VMSWidgetIntercom: Decodable, Hashable {
    
    public var id: Int!
    public var title: String?
    public var address: String?
    public var camera: VMSWidgetIntercomCamera?
    public var isOpenDoorApp: Bool!
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: VMSWidgetIntercom, rhs: VMSWidgetIntercom) -> Bool {
        return lhs.id == rhs.id
    }
    
    public init(id: Int, title: String? = nil, address: String? = nil, camera: VMSWidgetIntercomCamera? = nil, isOpenDoorApp: Bool) {
        self.id = id
        self.title = title
        self.address = address
        self.camera = camera
        self.isOpenDoorApp = isOpenDoorApp
    }
}

public final class VMSWidgetIntercomCamera: Decodable, Hashable {
    
    public enum StatusType: String, Decodable {
        case active
        case inactive
        case partial
        case empty
        case initial
    }
    
    public enum UserStatus: String, Decodable {
        case active
        case blocked
    }
    
    public var id: Int!
    public var status: StatusType? = .active
    public var userStatus: UserStatus? = .active
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: VMSWidgetIntercomCamera, rhs: VMSWidgetIntercomCamera) -> Bool {
        return lhs.id == rhs.id
    }
    
    public init(id: Int, status: StatusType? = nil, userStatus: UserStatus? = nil) {
        self.id = id
        self.status = status
        self.userStatus = userStatus
    }
    
}
