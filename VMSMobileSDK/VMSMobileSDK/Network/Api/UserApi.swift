
import Foundation
import UIKit
import Alamofire

public protocol UserApi {
    
    func getUser(completion: @escaping VMSResultBlock<VMSUser>)
    
    func changePassword(info: VMSChangePasswordRequest, completion: @escaping VMSResultBlock<VMSNoReply>)
    
    func logout(completion: @escaping VMSResultBlock<VMSNoReply>)
    
    func changeLanguage(language: String, completion: @escaping VMSResultBlock<VMSNoReply>)
}

extension VMS: UserApi {
    
    public func getUser(completion: @escaping VMSResultBlock<VMSUser>) {

        self.request(
            path: ApiPaths.UserSelf,
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
    
    public func logout(completion: @escaping VMSResultBlock<VMSNoReply>) {
        
        self.request(
            path: ApiPaths.Authorization.Logout,
            method: .post,
            parameters: ["uuid" : UIDevice.current.identifierForVendor!.uuidString]
        ) { [weak self] (response: VMSApiResult<Any>) in
            switch response {
            case .success(_):
                self?.headersBuilder.setAccessToken(nil)
                completion(.success(VMSNoReply()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func changePassword(info: VMSChangePasswordRequest, completion: @escaping VMSResultBlock<VMSNoReply>) {
        
        let params = [
            "current_password" : info.old,
            "password" : info.new,
            "password_confirmation" : info.confirmNew
        ]
        
        self.request(
            path: ApiPaths.UserSelf,
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
    
    public func changeLanguage(language: String, completion: @escaping VMSResultBlock<VMSNoReply>) {
        
        let params = [
            "language": language
        ]
        
        self.request(
            path: ApiPaths.UserSelf,
            method: .put,
            parameters: params
        ) { [weak self] (response: VMSApiResult<Any>) in
            switch response {
            case .success(_):
                self?.headersBuilder.setLanguage(language)
                completion(.success(VMSNoReply()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
