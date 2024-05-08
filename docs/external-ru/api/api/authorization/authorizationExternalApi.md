@toc API/Requests/Authorization/AuthorizationExternalApi

# AuthorizationExternalApi #

API для входа в приложение через внешний API.

Чтобы понять, доступна ли функциональность внешней аворизации на сервере, убедитесь, что значение параметра `isExternalAuthEnabled` в объекте `VMSBasicStatic` является `true`. См. `StaticsApi` для большей информации.


## Получение внешнего URL

Сперва необходимо получить URL для внешней авторизации, куда необходимо перенаправить пользователя.

```
getUrlForExternalLogin(completion: @escaping VMSResultBlock<VMSUrlStringResponse>)
```

## Работа с внешней авторизацией

После получения URL для внешне авторизации необходимо перенаправить уда пользователя. Мы рекомендуем использовать `AuthenticationServices` для этих целей.

После того, как пользователь авторизуется через внешний API, необходимо словить коллбэк со специальной схемой, которую вам предоставит ваш сервер. Внутри этого URL будет параметр `code`, который необходим для авторизации внутри приложения.

```
/// Example code

AuthenticationSession.init(
    url: externalURL, 
    callbackURLScheme: "SERVER_CALLBACK_SCHEME", 
    completionHandler: { (url, error) in
    guard let query = url?.query else {
        // Code must be provided in query of the url
    }
    print(query)    // code=AUTHORIZATION_CODE
})

```


## Вход

Параметр `code` получен, и можно логинить пользователя в приложении.

Если вы получите ошибку 419, это означает, что вам нужно удалить сессию. Для этого повторите этот запрос с параметром `sessionId`, который вы можете получить из ошибки. Больше информации см. в `VMSApiError`.

```
loginWithExternal(with login: VMSLoginExternalRequest, completion: @escaping VMSResultBlock<VMSUserResponse>)
```

### VMSLoginExternalRequest

Объект с необходимой информацией для внешнего входа. Для входа в систему вам понадобится `loginKey` или `code`.

```
init(loginKey: String?, code: String?, sessionId: String?)
```

`loginKey` — ключ входа, необходимый для входа в систему, полученный из `VMSSessionResponse` объекта в случае получения 419 ошибки. См. `VMSApiError` для большей информации

`code` — код, необходимый для входа в систему, полученный из авторизации через внешний API

`sessionId` — идентификатор сессии, который вы хотите заменить в случае получения ошибки 419. Дополнительную информацию см. в `VMSApiError`
