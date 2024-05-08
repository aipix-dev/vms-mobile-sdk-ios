
import Foundation

public final class VMSUser: Codable {
    
    public let id: Int
    public var phone: String?
    public var email: String?
    public var name: String?
    public var login: String?
    public var token: String?
    public var accessTokenId: String?
    public var permissions: [VMSPermission]?
    public var canUpdatePassword: Bool?
    
    public init(id: Int, phone: String? = nil, email: String? = nil, name: String? = nil, login: String? = nil, token: String? = nil, accessTokenId: String? = nil, permissions: [VMSPermission]? = nil, canUpdatePassword: Bool? = nil) {
        self.id = id
        self.phone = phone
        self.email = email
        self.name = name
        self.login = login
        self.token = token
        self.accessTokenId = accessTokenId
        self.permissions = permissions
        self.canUpdatePassword = canUpdatePassword
    }
}

extension VMSUser {
    
    public func hasPermission(_ permission: VMSPermission.PermissionType) -> Bool {
        return permissions?.contains(where: { (perm) -> Bool in
            return perm.type == permission
        }) ?? false
    }
    
}
