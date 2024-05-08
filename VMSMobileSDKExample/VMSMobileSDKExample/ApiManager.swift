

import Foundation
import VMSMobileSDK

final class ApiManager {
    
    static let baseUrl = "https://test.io"
    
    static let shared = ApiManager()
    
    var api: VMS
    
    var user: VMSUser?
    var userToken: String?
    var translations: VMSTranslationDict?
    var pusher: VMSSocketManager?
    var currentLanguage: String?
    
    init() {
        
        api = VMS(
            baseUrl: ApiManager.baseUrl,
            language: nil,  // default is english
            accessToken: nil
        )
        api.delegate = self
        
        getBasicStatic()
    }
    
    public func getBasicStatic() {
        api.getBasicStatic { [weak self] response in
            switch response {
            case .success(let staticObj):
                print("Login need captcha: \(staticObj.isCaptchaAvailable ?? false)")
                print("Available lagiages: \(staticObj.availableLocales)")
                self?.currentLanguage = staticObj.availableLocales.first
            case .failure(_):
                break
            }
        }
    }
    
    public func getTranslations() {
        guard let currentLanguage else { return }
        api.getTranslations(info: VMSTranslationsRequest(language: currentLanguage, revision: 0)) { [weak self] response in
            switch response {
            case .success(let object):
                self?.translations = object.json
            case .failure(_):
                break
            }
        }
    }
    
    public func initSocket(response: VMSSocketResponse) {
        guard let user = user, let token = userToken, let tokenId = user.accessTokenId else { return }
        let pusherApi = VMSPusherApi(
            baseUrl: ApiManager.baseUrl,
            socketUrl: response.wsUrl,
            appKey: response.appKey,
            userToken: token,
            userId: user.id,
            accessTokenId: tokenId
        )
        pusherApi.delegate = self
        pusherApi.connect()
        self.pusher = pusherApi
    }
}

extension ApiManager: VMSDelegate {
    func apiReceivedInfo(message: String) {
        
    }
    
    
    func apiRequestSucceed(_ request: VMSMobileSDK.VMSRequest) {
        
    }
    
    func apiDidReceiveError(_ error: VMSApiError, request: VMSMobileSDK.VMSRequest) {
        switch error.type {
        case .decode:
            print("There was an error while decoding objects")
        case .forbidden:
            print("This account does not have pemission to the feature")
        case .forceUpdate:
            print("Server side has critical updates. Update framework and your app")
        case .noConnection:
            print("You should have intenet connection")
        case .requestCanceled:
            print("Request was canceled")
        case .requestLimit:
            print("Too many attemps to the requst")
        case .serverError:
            print("Server error received")
        case .technical:
            print("There ae technical woks on server")
        case .unathorised:
            print("User is not athorised to request")
        case .unknown:
            print("Unknown error with status code: \(error.statusCode ?? 0), and message: \(error.message ?? "")")
        case .incorrectData(_):
            print("Handle inside your request method")
        case .sessionExpired(_):
            print("Handle inside your request method")
        @unknown default:
            print("Unknown error")
        }
    }
    
}

extension ApiManager: VMSSocketManagerDelegate {
    
    func changedConnectionState(from old: ConnectionState, to new: ConnectionState) {
        print("Pusher conection state: \(new.stringValue())")
    }
    
    func receivedError(error: PusherError) {
        print("Pusher error: \(error.message)")
    }
    
    func receivedAppSocket(socket: VMSAppSocketData) {
        print("Received application socket message")
    }
    
    func receivedIntercomSocket(socket: VMSIntercomSocketData) {
        print("Received intercom socket message")
    }
    
    func receivedInfo(message: String) {
        print("Information about socket")
    }
}
