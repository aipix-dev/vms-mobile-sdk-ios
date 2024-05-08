@toc API/Requests/Authorization/AuthorizationApi

# AuthorizationApi #

API для входа в приложение.


## Авторизация

Войдите в свое приложение. См. `StaticsApi`, чтобы узнать, нужна ли вам информация о капче для этого запроса.

Если вы получаете ошибку 429, это означает, что вам нужно удалить сессию. Для этого повторите этот запрос с параметром `sessionId`, который вы можете получить из этой ошибки. Больше информации см. в `VMSApiError`.

```
login(with login: VMSLoginRequest, completion: @escaping VMSResultBlock<VMSUserResponse>)
```

### VMSLoginRequest

Объект с необходимой информацией для запроса входа в систему.

```
init(login: String, password: String, captcha: String?, captchaKey: String?, sessionId: String?)
```

`login` — логин пользователя

`password` — пароль пользователя

`captcha` — капча, введенная пользователем с изображения

`captchaKey` — ключ капчи, полученный с сервера

`sessionId` — сессия, которую вы хотите заменить на новую


## Получение капчи

Если вам нужна капча для входа в систему, сначала сделайте этот запрос, чтобы получить ее.

```
getCaptcha(completion: @escaping VMSResultBlock<VMSCaptcha>)
```

### VMSCaptcha

Объект, который вы получаете с сервера с необходимой информацией для входа в систему.

`key` — ключ капчи, необходимый для входа в систему с капчей

`img` — представление base64 на изображении с капчей

`ttl` — допустимое время жизни запрошенной капчи

`getImage() -> UIImage?` — преобразует полученные данные img в изображение
