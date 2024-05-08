
import Foundation

struct VMSSocketUrl {
    
    let url: String
    let port: Int?
    let path: String
    let encrypted: Bool
    
    init(url: String) {
        
        let comps: URLComponents? = URLComponents.init(string: url)
        
        self.url = comps?.host ?? ""
        self.port = comps?.port
        self.path = comps?.path ?? ""
        self.encrypted = comps?.scheme == "wss"
    }
}
