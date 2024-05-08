
import Foundation
import Alamofire

public protocol StaticsApi {
    
    func checkUrl(api: String, completion: @escaping VMSResultBlock<VMSNoReply>)
    
    func getTranslations(info: VMSTranslationsRequest, completion: @escaping VMSResultBlock<VMSTranslationObject>)
    
    func getStatic(completion: @escaping VMSResultBlock<VMSStatic>)
    func getBasicStatic(completion: @escaping VMSResultBlock<VMSBasicStatic>)
    
    func sendFcmToken(token: String, completion: @escaping VMSResultBlock<VMSNoReply>)
    func sendApnToken(token: String, completion: @escaping VMSResultBlock<VMSNoReply>)
    func sendVoipToken(token: String, completion: @escaping VMSResultBlock<VMSNoReply>)
}

extension VMS: StaticsApi {
    
    public func checkUrl(api: String, completion: @escaping VMSResultBlock<VMSNoReply>) {
        self.request(
            url: self.urlBuilder.build(url: api, path: ApiPaths.BasicStatic),
            method: .get
        ) { (response: VMSApiResult<Any>) in
            switch response {
            case .success(_):
                completion(.success(VMSNoReply()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func getTranslations(info: VMSTranslationsRequest, completion: @escaping VMSResultBlock<VMSTranslationObject>) {
        let params: Parameters = [
            "language" : info.language,
            "revision" : info.revision
        ]
        
        self.request(
            path: ApiPaths.Dictionary,
            method: .get,
            parameters: params
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
    
    public func getStatic(completion: @escaping VMSResultBlock<VMSStatic>) {
        self.request(
            path: ApiPaths.Static,
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
    
    public func getBasicStatic(completion: @escaping VMSResultBlock<VMSBasicStatic>) {
        self.request(
            path: ApiPaths.BasicStatic,
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
    
    public func sendFcmToken(token: String, completion: @escaping VMSResultBlock<VMSNoReply>) {
        let params = [
            "fcm_token" : token
        ]
        self.request(
            path: ApiPaths.Devices,
            method: .put,
            parameters: params
        ) { (response: VMSApiResult<Any>) in
            switch response {
            case .success(_):
                completion(.success(VMSNoReply()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func sendApnToken(token: String, completion: @escaping VMSResultBlock<VMSNoReply>) {
        let params = [
            "apn_token" : token
        ]
        self.request(
            path: ApiPaths.Devices,
            method: .put,
            parameters: params
        ) { (response: VMSApiResult<Any>) in
            switch response {
            case .success(_):
                completion(.success(VMSNoReply()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func sendVoipToken(token: String, completion: @escaping VMSResultBlock<VMSNoReply>) {
        let params = [
            "voip_token" : token
        ]
        self.request(
            path: ApiPaths.Devices,
            method: .put,
            parameters: params
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
