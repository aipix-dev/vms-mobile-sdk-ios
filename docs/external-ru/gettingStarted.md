@toc Getting started

# VMSMobileSDK #

### Эта версия SDK включает: ###

* Alamofire
* CryptoSwift
* TweetNacl
* CocoaAsyncSocket

### Поддерживает: ###

* iOS 13.0
* Xcode 12.0

Этот гайд покажет, какие степы необходимы для того, чтобы подключить VMSMobileSDK.

### Эта SDK предлагает API для работы с запросами и плеер для просмотра камер. ###

* Версия 1.0.0

## Инсталляция

### Мануально

Скачайте проект. Либо сделайте архив проекта VMSMobileSDK и добавьте собранный архив VMSMobileSDK.framework в свой проект либо скопировать готовый архив VMSMobileSDK.framework из папки VMSMobileSDKExample.
В вашем проекте откройте Build Settings и добавьте в Header Search Paths следующий пункт "../FFMPEGResources" с опцией "recursive".

## Сетап API ###

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
api.getBasicStatic { response, error in
    // если `true`, то необходимо дополнительно сделать запрос getCaptcha() для оображения пользователю
    // response?.isCaptchaAvailable
}

let loginRequest = VMSLoginRequest(
    login: login,
    password: password,
    captcha: nil,
    captchaKey: nil,
    sessionId: nil
)
api.login(with: loginRequest) { response, error in
    if let error {
        switch error.type {
        case .sessionExpired(let sessionsList):
            // Слишком много сессий на данном аккаунте, необходимо удалить как минимум одну сессию, чтобы продолжить
            // Для этого отправьте реквест на логин повторно с указанным параметром sessionId сессии, которую необходимо удалить. Приповторном запросе капча не нужна, если уже была отправлена информация по капче в первом запросе
        default:
            // ошибка
        }
    } else {
        // успешная авторизация
    }
}
```

## Плеер ##

```
// Получите локализованные переводы с сервера:
api.getTranslations(info: VMSTranslationsRequest(language: VMSLanguage.english, revision: 0)) { response, error in
    
}

// Базовая информация, необходимая для корректной работы плеера
api.getStatic { response, error in
    // response?.markTypes // доступные типы событий
    // response?.videoRates // доступные скорости воспроизведения
}

// Информация о камере
api.getCamera(with: camera.id) { camera, error in
}

// VMSPlayerTranslations - это словарь с переводами, основанный на том, который нужно получить с сервера
let modelTranslations = VMSPlayerTranslations.init(translations: translations)

// Опции для плеера
let options = VMSPlayerOptions.init(
    language: VMSLanguage.english,
    allowVibration: true,
    allowSoundOnStart: true,
    allEventTypes: markTypes,
    videoRates: videoRates
)

// Модель плеера               
let model = VMSPlayerViewModel(
    camera: cam,
    groupCameras: group,
    user: user,
    translations: modelTranslations,
    playerApi: api,
    options: options
)
// Контроллер для плеераы
let vc = VMSPlayerController.initialization(viewModel: model, delegate: self)
self.navigationController?.pushViewController(vc, animated: true)
```
