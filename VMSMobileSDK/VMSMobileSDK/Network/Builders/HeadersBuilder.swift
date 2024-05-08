
import Foundation
import UIKit

public protocol HeadersBuilder {
    func setAccessToken(_ token: String?)
    func setSocketId(_ socketId: String?)
    func setLanguage(_ language: String)
    func getLanguage() -> String
    func getHeaders() -> [String : String]
}

public class HeadersBuilderImpl: HeadersBuilder {
    
    private var agent: String
    private var accessToken: String?
    private var socketId: String?
    private var currentLanguage: String
    
    init(language: String?, accessToken: String?) {
        self.accessToken = accessToken
        self.currentLanguage = language ?? "en"
        
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"), let currentVersion = NSDictionary(contentsOfFile: path)?["CFBundleVersion"] as? String, let shortVersion = NSDictionary(contentsOfFile: path)?["CFBundleShortVersionString"] as? String {
            self.agent = "\(UIDevice.modelName) \(UIDevice.current.systemVersion) / \(shortVersion).\(currentVersion) / IOS"
        } else {
            self.agent = "\(UIDevice.modelName) \(UIDevice.current.systemVersion) / IOS"
        }
    }
    
    public func setAccessToken(_ token: String?) {
        self.accessToken = token
    }
    
    public func setSocketId(_ socketId: String?) {
        self.socketId = socketId
    }
    
    public func setLanguage(_ language: String) {
        self.currentLanguage = language
    }
    
    public func getLanguage() -> String {
        return self.currentLanguage
    }
    
    public func getHeaders() -> [String : String] {
        
        var result = [
            APIKeys.Accept.header           : APIKeys.Accept.value,
            APIKeys.ContentType.header      : APIKeys.ContentType.value,
            APIKeys.UUID.header             : UIDevice.current.identifierForVendor!.uuidString,
            APIKeys.UserAgent.header        : agent,
            APIKeys.Client.header           : APIKeys.Client.value,
            APIKeys.Language.header         : currentLanguage,
            APIKeys.BackendVersion.header   : APIKeys.BackendVersion.value
        ]
        
        if let accessToken = self.accessToken {
            result[APIKeys.Authorization.header] = APIKeys.Authorization.value + accessToken
        }
        
        if let socketId = self.socketId {
            result[APIKeys.Socket.header] = socketId
        }
        
        return result
    }
    
}

enum APIKeys {
    
    enum Authorization {
        static let header = "Authorization"
        static let value = "Bearer "
    }
    
    enum Accept {
        static let header = "Accept"
        static let value = "application/json"
    }
    
    enum ContentType {
        static let header = "Content-Type"
        static let value = "application/json"
    }
    
    enum UUID {
        static let header = "X-UUID"
    }
    
    enum UserAgent {
        static let header = "User-Agent"
    }
    
    enum Language {
        static let header = "hl"
    }
    
    enum Client {
        static let header = "X-Client"
        static let value = "ios"
    }
    
    enum Socket {
        static let header = "X-Socket-ID"
    }
    
    enum BackendVersion {
        static let header = "X-Version"
        static let value = "24.03.0.0"
    }
}
