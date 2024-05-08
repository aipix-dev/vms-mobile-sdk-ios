
import Foundation
import Alamofire

extension ApiPaths {
    
    static let ExternalAuthUrl = "external/auth/url" // GET
    static let LoginExternalHandle = "login"     //for web use only
    static let ExternalAuthCallback = "external/auth/callback" // POST
}

public protocol AuthorizationExternalApi {
    
    func loginWithExternal(with login: VMSLoginExternalRequest, completion: @escaping VMSResultBlock<VMSUserResponse>)
    func getUrlForExternalLogin(completion: @escaping VMSResultBlock<VMSUrlStringResponse>)
}

extension VMS: AuthorizationExternalApi {
    
    public func loginWithExternal(with login: VMSLoginExternalRequest, completion: @escaping VMSResultBlock<VMSUserResponse>) {
        
        var params = Parameters()
        params["code"] = login.code
        params["key"] = login.loginKey
        params["session_id"] = login.sessionId
        
        self.request(
            path: ApiPaths.ExternalAuthCallback,
            method: .post,
            parameters: params
        ) { [weak self] (response: VMSApiResult<Any>) in
                switch response {
                case .success(let object):
                    guard let self else { return }
                    let result: VMSApiResult<VMSUserResponse> = self.decode(data: object)
                    switch result {
                    case .success(let decoded):
                        self.headersBuilder.setAccessToken(decoded.accessToken)
                        completion(.success(decoded))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    public func getUrlForExternalLogin(completion: @escaping VMSResultBlock<VMSUrlStringResponse>) {
        self.request(
            path: ApiPaths.ExternalAuthUrl,
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
