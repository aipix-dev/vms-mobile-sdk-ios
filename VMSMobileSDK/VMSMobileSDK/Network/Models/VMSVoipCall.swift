
import Foundation

public struct VMSVoipCall: Decodable {
    
    public let sip: String
    public let number: String
    public let host: String
    
    public init(sip: String, number: String, callId: String, host: String) {
        self.sip = sip
        self.number = number
        self.host = host
    }
}


