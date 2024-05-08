@toc API/VMSApiError

# VMSApiError #

Если в запросах произошла какая-либо ошибка, вы получите объект `VMSApiError`.

`statusCode` — код ошибки, если ошибка исходила от сервера, иначе `nil`

`type` — тип ошибки, будет содержать дополнительную информацию, если она была

`message` — информационное сообщение, отправленное с сервера. Если ошибка произошла не на сервере, вернет `nil`


### Типы ошибок

```
public enum ErrorType: Equatable {
    case unathorised                                /// status code 401
    case forbidden                                  /// status code 403
    case notFound                                   /// status code 404
    case forceUpdate                                /// status code 409
    case sessionExpired(VMSSessionResponse?)        /// status code 419
    case incorrectData(ServerError?)                /// status code 400, 422
    case requestLimit                               /// status code 429
    case technical                                  /// status code 503
    case serverError                                /// status code 500
    case unknown                                    /// Unknown error
    case noConnection                               /// No internet connection
    case decode                                     /// Error during decoding server object
    case requestCanceled                            /// Request was canceled
    
    public var description: String {
        switch self {
        case .unathorised:
            return "You are unathorised"
        case .forbidden:
            return "Access forbidden"
        case .forceUpdate:
            return "There is a critical update on server side. You need to update SDK"
        case .sessionExpired:
            return "Your session expired"
        case .incorrectData:
            return "Incorrect input data"
        case .requestLimit:
            return "You reached request limit"
        case .technical:
            return "Server technical works error"
        case .serverError:
            return "Unknown server error"
        case .unknown:
            return "Unknown error"
        case .noConnection:
            return "There is no internet connection"
        case .decode:
            return "Error during JSON serialization decoding"
        case .requestCanceled:
            return "Request was canceled"
        }
    }
}
```
