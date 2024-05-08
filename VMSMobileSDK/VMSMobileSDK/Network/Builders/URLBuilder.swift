
import Foundation

public protocol URLBuilder {
    
    func getBaseUrl() -> String
    func build(path: String) -> String
    func build(path: String, version: Int?) -> String
    func build(url: String, path: String) -> String
    
}

public class URLBuilderImpl: URLBuilder {
    
    static let version: Int = 1
    private var baseUrl: String
    
    init(baseUrl: String) {
        self.baseUrl = baseUrl
    }
    
    open func build(path: String) -> String {
        return build(path: path, version: nil)
    }
    
    open func build(path: String, version: Int? = nil) -> String {
        if let v = version {
            return baseUrl + "/api/v\(v)/" + path
        }
        return baseUrl + "/api/v\(URLBuilderImpl.version)/" + path
    }
    
    open func build(url: String, path: String) -> String {
        if path.starts(with: "/") {
            return url + "/api/v\(URLBuilderImpl.version)" + path
        }
        return url + "/api/v\(URLBuilderImpl.version)/" + path
    }
    
    open func getBaseUrl() -> String {
        return baseUrl
    }
}
