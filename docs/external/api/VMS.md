@toc API/Initialization

# VMS initialization #

Uses Alamofire of 4.8.2 version.

https://github.com/Alamofire/Alamofire

Main entry point to establish connection between application and server.

## Initialization

For simple initialization only url of your server is required

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

### Language

Default language is english. You can receive available languages from server inside basic static information. See `StaticsApi` for more details.

Use this method if you want to change language after initialization of `VMS`. Calling this method is required if you want server to send responses with proper localizations. If language is changed via `UserApi` `changeLanguage(...)` method, language will be changed automatically.

```
setLanguage(_ language: String)
```

If you want to know what curret language VMS uses in requests, call whis method.

```
getLanguage() -> String
```


### Access token

For authorised users you can set user's access token. In this case you can skip authorization flow.
Otherwise SDK will set this parameter by itself after login request.


### Socket ID

Use this funtion to set socket Id for requests headers. See `VMSPusherApi` to know how to get it.

```
setSocketId(socketId: String?)
```


## Delegate

Set delegate if you want to handle errors. Here you will receive all possible errors, but we suggest additionally handle 400, 403, 404, 422 and 429 inside requests. See `VMSApiError` for more details.

```
public protocol VMSDelegate: AnyObject {
    func apiDidReceiveError(_ error: VMSApiError, request: VMSRequest)
    
    func apiRequestSucceed(_ request: VMSRequest)
}
```

## Download archive

Part of video will be downloaded from url and saved.

```
func downloadArchiveRequest(
    url: URL,
    destinationUrl: URL,
    progressHandler: @escaping ((Progress) -> Void),
    completionHandler: @escaping ((Error?) -> Void)
)
```

`url` - from where download archive

`destinationUrl` - where to save downloaded file

`progressHandler` - track the progress of downloading process

`completionHandler` - will be called when download is finished


### Cancel download archive request

```
cancelDownloadArchiveRequest()
```

## Repeat request

If you want to repeat any request you can use this function. You can receive the request from delegate methods.

```
repeatRequest(_ request: VMSRequest)
```

## Responses

To all requests you should send completion `VMSResultBlock` block.

```
typealias VMSResultBlock<T : Codable> = (VMSApiResult<T>) -> Void
```

Where `VMSApiResult` is a generic enum.

```
VMSApiResult<T> {
    case success(T)
    case failure(VMSApiError)
}
```

For more information about `VMSApiError` check `VMSApiError.md`.

In case of empty response `succcess` case returns `VMSNoReply` object.

```
struct VMSNoReply: Codable {}
```
