
import Foundation
import Alamofire

public protocol CallsApi {
    
    func callStatus(with callId: Int, completion: @escaping VMSResultBlock<VMSIntercomCall>)
    
    func callAnswered(callId: Int, completion: @escaping VMSResultBlock<VMSVoipCall>)
    
    func callCanceled(callId: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
    
    func callEnded(callId: Int, completion: @escaping VMSResultBlock<VMSNoReply>)
}

extension VMS: CallsApi {
    
    public func callStatus(with callId: Int, completion: @escaping VMSResultBlock<VMSIntercomCall>) {
        
        self.request(
            path: ApiPaths.Calls.status(id: callId),
            method: .get
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
    
    public func callAnswered(callId: Int, completion: @escaping VMSResultBlock<VMSVoipCall>) {
        
        self.request(
            path: ApiPaths.Calls.answer(id: callId),
            method: .post
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
    
    public func callCanceled(callId: Int, completion: @escaping VMSResultBlock<VMSNoReply>) {
        
        self.request(
            path: ApiPaths.Calls.cancel(id: callId),
            method: .post
        ) { (response: VMSApiResult<Any>) in
            switch response {
            case .success:
                completion(.success(VMSNoReply()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func callEnded(callId: Int, completion: @escaping VMSResultBlock<VMSNoReply>) {
        
        self.request(
            path: ApiPaths.Calls.end(id: callId),
            method: .post
        ) { (response: VMSApiResult<Any>) in
            switch response {
            case .success:
                completion(.success(VMSNoReply()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
