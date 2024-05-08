
import Foundation

public final class VMSStream: Decodable {
    
    public enum QualityType: String, Codable {
        case low
        case high
    }
    
    public enum StatusType: String, Codable {
        case active
        case inactive
        case NULL
    }
    
    public enum VideoCodec: String, Codable {
        case h264 = "H264"
        case h265 = "H265"
    }
    
    public let id: Int
    public var type: QualityType!
    public var status: StatusType!
    public var hasSound: Bool!
    public var videoCodec: VideoCodec!
    
    public init(id: Int, type: QualityType, hasSound: Bool, status: StatusType, videoCodec: VideoCodec) {
        self.id = id
        self.status = status
        self.hasSound = hasSound
        self.type = type
        self.videoCodec = videoCodec
    }
}
