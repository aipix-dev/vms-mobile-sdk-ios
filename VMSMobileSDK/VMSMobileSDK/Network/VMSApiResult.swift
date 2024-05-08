
import Foundation

public typealias VMSResultDataBlock = (VMSApiResult<Any>) -> Void
public typealias VMSResultBlock<T : Decodable> = (VMSApiResult<T>) -> Void

/// Defines whether the VMSMobileSDK request  was successful and contains a result or there was an error
///
/// - Success: Represents a associated value of ths request if it was successfull
/// - Failure: Represent a failure of the request
@frozen public enum VMSApiResult<T> {
    case success(T)
    case failure(VMSApiError)
}

public struct VMSNoReply: Decodable {}

public struct VMSServerError: Decodable {
    
    public let message: String
    public let errors: [String: [String]]
    
    public func allMessages() -> String {
        var errorString = ""
        for (_, value) in errors {
            errorString = value.joined(separator: "\n")
        }
        return errorString
    }
}


