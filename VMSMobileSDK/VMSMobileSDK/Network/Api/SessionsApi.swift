
import Foundation
import Alamofire

public protocol SessionsApi {
    
    func getSessionsList(completion: @escaping VMSResultBlock<[VMSSession]>)
    
    func deleteSession(with id: String, completion: @escaping VMSResultBlock<VMSNoReply>)
}

extension VMS: SessionsApi {
    
    public func getSessionsList(completion: @escaping VMSResultBlock<[VMSSession]>) {
        
        self.request(
            path: ApiPaths.Sessions.List,
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
    
    public func deleteSession(with id: String, completion: @escaping VMSResultBlock<VMSNoReply>) {
        self.request(
            path: ApiPaths.Sessions.delete(id: id),
            method: HTTPMethod.post
        ) { (response: VMSApiResult<Any>) in
            switch response {
            case .success(_):
                completion(.success(VMSNoReply()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
