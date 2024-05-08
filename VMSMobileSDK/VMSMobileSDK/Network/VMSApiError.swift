
import Foundation

public final class VMSApiError {
    
    public var statusCode: Int?
    public var type: ErrorType
    
    /// Message send from server together with error
    public var message: String?
    
    public init(statusCode: Int?, type: ErrorType, message: String? = nil) {
        self.statusCode = statusCode
        self.type = type
        self.message = message
    }
    
    /// Represets errors that can happen in VMSMobileSDK
    public enum ErrorType: Equatable {
        /// 401
        case unathorised
        /// 403
        case forbidden
        /// 404
        case notFound
        /// 409
        case forceUpdate
        /// 419
        case sessionExpired(VMSSessionResponse?)
        /// 400, 422
        case incorrectData(VMSServerError?)
        /// 429
        case requestLimit
        /// 503
        case technical
        /// 500
        case serverError
        /// Unknown error
        case unknown
        /// No internet connection
        case noConnection
        /// Error during decoding server object
        case decode
        /// Request was canceled
        case requestCanceled
        
        public var description: String {
            switch self {
            case .unathorised:
                return "You are unathorised"
            case .forbidden:
                return "Access forbidden"
            case .notFound:
                return "Route not found"
            case .forceUpdate:
                return "There is a critical update on server side. You need to update SDK"
            case .sessionExpired:
                return "Your session expired"
            case .incorrectData:
                return "Incorrrect input data"
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
        
        public static func == (lhs: VMSApiError.ErrorType, rhs: VMSApiError.ErrorType) -> Bool {
            switch (lhs, rhs) {
            case (.unathorised, .unathorised): return true
            case (.forbidden, .forbidden): return true
            case (.forceUpdate, .forceUpdate): return true
            case (.sessionExpired, .sessionExpired): return true
            case (.incorrectData, .incorrectData): return true
            case (.requestLimit, .requestLimit): return true
            case (.technical, .technical): return true
            case (.serverError, .serverError): return true
            case (.unknown, .unknown): return true
            case (.noConnection, .noConnection): return true
            case (.decode, .decode): return true
            case (.requestCanceled, .requestCanceled): return true
            default: return false
            }
        }
    }
    
}
