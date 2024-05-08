@toc API/Requests/Authorization/AuthorizationApi

# AuthorizationApi #

Api to login to the app


## Login

Login to your application. See `StaticsApi` to know if you need captcha information for this request.

If you receive 429 error, that means you need to delete session. For that repeat this request with `sessionId` parameter that you can take from error. See `VMSApiError` details for that information.

```
login(with login: VMSLoginRequest, completion: @escaping VMSResultBlock<VMSUserResponse>)
```

### VMSLoginRequest

Object with needed information for login request.

```
init(login: String, password: String, captcha: String?, captchaKey: String?, sessionId: String?)
```

`login` - user's login

`password` - user's password

`captcha` - captcha user entered from image

`captchaKey` - captcha key received from server

`sessionId` - session you want to replace with the new one


## Get captcha

If you need captcha fo login make this request at first to get it.

```
getCaptcha(completion: @escaping VMSResultBlock<VMSCaptcha>)
```

### VMSCaptcha

Object you receive from server with needed captcha information for login.

`key` - captcha key needed to login with captcha

`img` - base64 representation on captcha image

`ttl` - valid time of living of requested captcha

`getImage() -> UIImage?` - converts received img data into image
