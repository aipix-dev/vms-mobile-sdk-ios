# VMSMobileSDK #

### This version of SDK includes: ###

* Alamofire
* CryptoSwift
* TweetNacl

### Supports: ###

* iOS 13.0
* Xcode 12.0

This guide would normally document whatever steps are necessary to get your application up and running.

### This SDK provides API for requests and a player to work with cameras. ###

* Version 1.0.0

## Installation

### Manually

Download project. You can either archive VMSMobileSDK project and add VMSMobileSDK.framework to your project or copy VMSMobileSDK.framework from VMSMobileSDKExample folder.

## Set up API ###

```
import VMSMobileSDK

let apiUrl = "https://example.com"
var api = VMS(
        baseUrl: apiUrl,
        language: nil,
        accessToken: nil
    )
    api.delegate = self
```

### Login ###

```
api.getBasicStatic { response in
    // indicates if you need to make getCaptcha() request additionally to get captcha information
    // response?.isCaptchaAvailable
}

let loginRequest = VMSLoginRequest(
    login: login,
    password: password,
    captcha: nil,
    captchaKey: nil,
    sessionId: nil
)
api.login(with: loginRequest) { response in
    switch response {
        case .success(let user):
            // successfull login
        case .failure(let error):
            switch error.type {
                case .sessionExpired(let sessionsList):
                    // Too many sessions on this account, you have to delete at least one of them to be able to proceed
                    // For that make a login requst again and st sessionId parameter with the session id you want to delete
                default:
                    // error
            }
    }
}

### Show Player ###

```
// At first get translations from server:
api.getTranslations(info: VMSTranslationsRequest(language: VMSLanguage.english, revision: 0)) { response in
    
}

// Base information you eed for player
api.getStatic { response in
    // response?.markTypes // event types available
    // response?.videoRates // video speed rates available
}

// Get camera information
api.getCamera(with: camera.id) { response in
}

// VMSPlayerTranslations is a dictionary with translations based on the one you got from server
let modelTranslations = VMSPlayerTranslations.init(translations: translations)

// Options for player model
let options = VMSPlayerOptions.init(
    language: VMSLanguage.english,
    allowVibration: true,
    allowSoundOnStart: true,
    allEventTypes: markTypes,
    videoRates: videoRates
)

// Model for player                
let model = VMSPlayerViewModel(
    camera: cam,
    groupCameras: group,
    user: user,
    translations: modelTranslations,
    playerApi: api,
    options: options
)
// Player controller
let vc = VMSPlayerController.initialization(viewModel: model, delegate: self)
self.navigationController?.pushViewController(vc, animated: true)
```
