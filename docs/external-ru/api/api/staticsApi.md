@toc API/Requests/StaticsApi

# StaticsApi #

API для получения базовой информации с вашего сервера и отправки на сервер возможных токенов.


## Базовая статика

Получение информации, необходимой для корректной работы приложения.

```
getBasicStatic(completion: @escaping VMSResultBlock<VMSBasicStatic>)
```

### VMSBasicStatic

Объект, который вы получаете с сервера, с информацией, необходимой для работы приложения.

`isCaptchaAvailable` — `true`, если вам нужна информация о капче для входа в систему

`isExternalAuthEnabled` — `true`, если вы можете войти в систему с помощью внешнего сервиса

`availableLocales` - список доступных языков, которые поддерживаются сервером

`version` — текущая версия бэкэнда


## Статика

Получение базовой информации, необходимой для плеера.

```
getStatic(completion: @escaping VMSResultBlock<VMSStatic>)
```

### VMSStatic

Объект, который вы получаете с сервера, с информацией, необходимой для запуска некоторых функций.

`cameraIssues` — проблемы, по которым можно отправить отчет на сервер

`videoRates` — скорости воспроизведения видео, доступные плееру

`markTypes` — типы отметок, доступные пользователю

`systemEvents` — типы системных событий, доступные пользователю

`analyticEvents` — типы событий аналитики, доступные пользователю

`analyticTypes` — типы аналитики, доступные пользователю


## Проверка URL

Проверьте, верен ли указанный API URL.

```
checkUrl(api: String, completion: @escaping VMSResultBlock<VMSNoReply>)
```


## Получение всех переводов

Получение переводов данного языка и из конкретной версии.

```
getTranslations(info: VMSTranslationsRequest, completion: @escaping VMSResultBlock<VMSTranslationObject>)
```

### VMSTranslationsRequest

Объект с необходимой информацией для получения переводов.

```
init(language: String, revision: Int)
```

`language` — список досупных языков содержится в объекте `VMSBasicStatic`. См. `StaticsApi` для большей информации

`revision` — номер ревизии, из которой вы получите изменения в переводах. Установите значение `0`, чтобы получить все переводы


## Токены

### FCM

Отправьте токен FCM на сервер, если у вас есть firebase.

```
sendFcmToken(token: String, completion: @escaping VMSResultBlock<VMSNoReply>)
```

### APNS

Отправьте токен APNS на сервер, если вы его используете.

```
sendApnToken(token: String, completion: @escaping VMSResultBlock<VMSNoReply>)
```

### VOIP

Отправьте токен VOIP для звонков, если вы его используете.

```
sendVoipToken(token: String, completion: @escaping VMSResultBlock<VMSNoReply>)
```
