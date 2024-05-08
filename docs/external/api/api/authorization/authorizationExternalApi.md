@toc API/Requests/Authorization/AuthorizationExternalApi

# AuthorizationExternalApi #

Api to login to the app via external api.

In order to know if this functionality is available on server make sure that parameter `isExternalAuthEnabled` of `VMSBasicStatic` object is set to `true`. See `StaticsApi` for more information.


## Get external URL

At first you need to get an external URL to where you can redirect user for authorization.

```
getUrlForExternalLogin(completion: @escaping VMSResultBlock<VMSUrlStringResponse>)
```


## Work with external authorization

After getting an external URL you should navigate user there. We recommend using `AuthenticationServices` for that purpose.

After user authorized you need to catch a specific callback provided by your server. In this callback server will provide `code` parameter that you can use to login that user inside application.

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


## External login

Parameter `code` rceived and now user is ready to be logined inside application.

If you receive 419 error, that means you need to delete session. For that repeat this request with `sessionId` parameter that you can take from error. See `VMSApiError` details for that information.

```
loginWithExternal(with login: VMSLoginExternalRequest, completion: @escaping VMSResultBlock<VMSUserResponse>)
```

### VMSLoginExternalRequest

Object with needed information for external login. You need either `loginKey` or `code` to be able to login.

```
init(loginKey: String?, code: String?, sessionId: String?)
```

`loginKey` - key you get from `VMSSessionResponse` object in case you receive 419 error from `loginWithExternal` response. See `VMSApiError` for more details

`code` - code you get from exteral authorization needed to login

`sessionId` - session id you want to replace in case you receive 419 error. See `VMSApiError` for more details
