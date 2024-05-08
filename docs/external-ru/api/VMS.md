@toc API/Initialization


# Инициализация VMS #

Используется Alamofire версии 4.8.2.

https://github.com/Alamofire/Alamofire

Основная точка входа для установления соединения между приложением и сервером.

## Инициализация

Для простой инициализации требуется только URL вашего сервера.

```
import VMSMobileSDK

let apiUrl = "https://example.com"
var api = VMS(
        baseUrl: apiUrl,
        language: language,
        accessToken: nil
    )
    api.delegate = self
```

### Язык

Опциональный параметр. По умолчанию английский. Список доступных языков можно получить от сервера. См. `StaticsApi` для большей информации.

Используйте следующий метод, чтобы установить язык после инициализации `VMS`. Вызов этого методв необходим, если вы хоите, чтобы сервер присылал ответы с корректной локализацией. Если язык меняется через метод `changeLanguage(...)` в `UserApi`, язык поменяется автоматически.

```
setLanguage(_ language: String)
```

Усли необходима информация, какой язык в данным момент использует VMS для запросов, используйте этот метод.

```
getLanguage() -> String
```


### Токен доступа

Для авторизованных пользователей вы можете установить токен доступа пользователя. В этом случае вы можете пропустить процесс авторизации.

В противном случае SDK самостоятельно установит этот параметр после запроса на вход.


### Идентификатор сокетного подключения

Используйте эту функцию, чтобы установить идентификатор для заголовков запросов. См. `VMSPusherApi`, чтобы узнать, как его получить.

```
setSocketId(socketId: String?)
```


## Делегирование

Установите делегирование, если вы хотите обрабатывать ошибки. Здесь вы получите все возможные ошибки, но мы предлагаем дополнительно обрабатывать внутренние запросы 400, 403, 404, 422 и 429. См. `VMSApiError` для более подробной информации.

```
public protocol VMSDelegate: AnyObject {
    func apiDidReceiveError(_ error: VMSApiError, request: VMSRequest)
    
    func apiRequestSucceed(_ request: VMSRequest)
}
```

## Скачивание архива

Часть видео будет загружена по URL и сохранена.

```
func downloadArchiveRequest(
    url: URL,
    destinationUrl: URL,
    progressHandler: @escaping ((Progress) -> Void),
    completionHandler: @escaping ((Error?) -> Void)
)
```

`url` — откуда скачать архив

`destinationUrl` — куда сохранить загруженный файл

`progressHandler` — отслеживать ход процесса загрузки

`completionHandler` — будет вызван после завершения загрузки


### Отменить запрос на скачивание архива

```
cancelDownloadArchiveRequest()
```


## Повтор запроса

Для повтора запроса необходимо вызвать эту функцию. Сам запрос можно получить из методов делегата.

```
repeatRequest(_ request: VMSRequest)
```

## Ответы

Во все запросы необходимо передавать блок кода `VMSResultBlock`, который вызовется, когда запрос получит от сервера ответ.

```
typealias VMSResultBlock<T : Codable> = (VMSApiResult<T>) -> Void
```

Где `VMSApiResult` - это generic enum.

```
VMSApiResult<T> {
    case success(T)
    case failure(VMSApiError)
}
```

Для больше информации о `VMSApiError` см. `VMSApiError.md`.

Вслучае пустого ответа вариант `succcess` вернет `VMSNoReply` объект.

```
struct VMSNoReply: Codable {}
```
