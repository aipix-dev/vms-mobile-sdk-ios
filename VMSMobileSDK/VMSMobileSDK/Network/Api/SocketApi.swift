
import Foundation
import Alamofire

public protocol SocketApi {
    
    func getSocketUrl(completion: @escaping VMSResultBlock<VMSSocketResponse>)
}

extension VMS: SocketApi {
    
    public func getSocketUrl(completion: @escaping VMSResultBlock<VMSSocketResponse>) {
        
        self.request(
            path: ApiPaths.Socket.WsUrl,
            method: HTTPMethod.get
        ) { [weak self] (response: VMSApiResult<Any>) in
            
            switch response {
            case .success(let object):
                guard let self else { return }
                completion(self.decode(data: object))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
