
import Foundation
import Alamofire

public protocol AuthorizationApi {
    
    func login(with login: VMSLoginRequest, completion: @escaping VMSResultBlock<VMSUserResponse>)
    
    func getCaptcha(completion: @escaping VMSResultBlock<VMSCaptcha>)
}

extension VMS: AuthorizationApi {
    
    public func login(with login: VMSLoginRequest, completion: @escaping VMSResultBlock<VMSUserResponse>) {
        
        var params: Parameters = [
            "password" : login.password,
            "login" : login.login,
            "rememberMe" : false
        ]
        if let sessionId = login.sessionId {
            params["session_id"] = sessionId
        }
        params["captcha"] = login.captcha
        params["key"] = login.captchaKey
        
        self.request(
            path: ApiPaths.Authorization.Token,
            method: HTTPMethod.post,
            parameters: params
        ) { [weak self] (response: VMSApiResult<Any>) in
            
            switch response {
            case .success(let object):
                guard let self = self else { return }
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
    
    public func getCaptcha(completion: @escaping VMSResultBlock<VMSCaptcha>) {
        self.request(
            path: ApiPaths.Authorization.Captcha,
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
}
