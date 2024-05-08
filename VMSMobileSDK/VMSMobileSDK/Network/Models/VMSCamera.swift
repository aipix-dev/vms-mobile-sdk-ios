
import Foundation
import UIKit

public final class VMSCamera: Decodable {
    
    public let id: Int
    public var status: VMSCameraStatusType!
    public var streams: [VMSStream]?
    public var name: String?
    public var startAt: Date?
    public var previewDateString: String?
    public var previewUrl: String?
    public var prettyText: String?
    public var isFavorite: Bool = false
    public var isRestrictedLive: Bool? = false
    public var isRestrictedArchive: Bool? = false
    public var archiveRanges: [VMSArchiveRanges]?
    public var services: VMSCameraServices?
    public var hasPTZ: Bool?
    public var hasMotionDetect: Bool?
    public var durations: [CGFloat]?
    public var startFrom: [CGFloat]?
    public var userStatus: VMSUserStatusType?
    public var isBridge: Bool = false
    
    public init(id: Int) {
        self.id = id
        self.status = .active
    }
    
    public init (from decoder: Decoder) throws {
        let container =  try decoder.container (keyedBy: CodingKeys.self)
        id = try container.decode (Int.self, forKey: .id)
        prettyText = try? container.decode (String.self, forKey: .prettyText)
        status = try container.decode (VMSCameraStatusType.self, forKey: .status)
        streams = try? container.decode([VMSStream].self, forKey: .streams)
        name = try? container.decode(String.self, forKey: .name)
        isFavorite = try container.decode (Bool.self, forKey: .isFavorite)
        isRestrictedLive = try? container.decode (Bool.self, forKey: .isRestrictedLive)
        isRestrictedArchive = try? container.decode (Bool.self, forKey: .isRestrictedArchive)
        let started = try? container.decode(String.self, forKey: .startAt)
        startAt = DateFormatter.serverUTC.date(from: (started ?? "")) ?? Date()
        userStatus = try? container.decode (VMSUserStatusType.self, forKey: .userStatus)
        isBridge = (try? container.decodeIfPresent (Bool.self, forKey: .isBridge)) ?? false
        let ranges = try? container.decode ([VMSArchiveRanges].self, forKey: .archiveRanges)
        archiveRanges = cutUnavailableArchiveRanges(ranges: ranges, startAt: startAt ?? Date())
        
        services = try? container.decode (VMSCameraServices.self, forKey: .services)
        
        if let ptz = services?.ptz, let motionDetect = services?.motionDetect {
            hasPTZ = ptz
            hasMotionDetect = motionDetect
        } else {
            hasPTZ = false
            hasMotionDetect = false
        }
        
        durations = archiveRanges.map ( {$0.map { (duration) -> CGFloat in
            return duration.duration ?? 0
            }} )
        
        startFrom = archiveRanges.map ( {$0.map { (from) -> CGFloat in
            return from.from ?? 0
            }} )
    }
    
    enum CodingKeys: String, CodingKey {
        case id, status, streams, name, isFavorite, isRestrictedLive, isRestrictedArchive, userStatus, services, startAt, archiveRanges, prettyText, isBridge
    }
    
    private func cutUnavailableArchiveRanges(ranges: [VMSArchiveRanges]?, startAt: Date) -> [VMSArchiveRanges]? {
        guard let r = ranges else { return nil }
        var newRanges: [VMSArchiveRanges] = []
        for (index, range) in r.enumerated() {
            let from = Date(timeIntervalSince1970: TimeInterval(range.from ?? 0))
            let end = Date(timeIntervalSince1970: TimeInterval(range.rangeEnd() ?? 0))
            if from >= startAt {
                newRanges.append(contentsOf: r[index..<r.count])
                break
            } else if end > startAt {
                let newStart = CGFloat(startAt.timeIntervalSince1970)
                let difference = newStart - (range.from ?? 0)
                range.from = newStart
                range.duration = (range.duration ?? 0) - difference
                newRanges.append(range)
            }
        }
        return newRanges
    }
}

public enum VMSUserStatusType: String, Decodable {
    case active
    case blocked
}

public enum VMSCameraStatusType: String, Decodable {
    case active
    case inactive
    case partial
    case empty
    case initial
}

extension VMSCamera {
    
    public func highStream() -> VMSStream? {
        return streams?.filter({ (stream) -> Bool in
            return stream.type == .high && stream.status == .active
        }).first
    }
    
    public func lowStream() -> VMSStream? {
        return streams?.filter({ (stream) -> Bool in
            return stream.type == .low && stream.status == .active
        }).first
    }
    
    public func nullStreams() -> VMSStream? {
        return streams?.filter({ (stream) -> Bool in
            return stream.status == .NULL
            }).first
    }
}

extension VMSCamera: Video {
    
    var cameraHighStream: VMSStream? {
        return highStream()
    }
    
    var cameraStatus: VMSCameraStatusType {
        return status
    }
    
    var rangeDurations: [CGFloat] {
        return durations ?? []
    }
    
    var rangeStarts: [CGFloat] {
        return startFrom ?? []
    }
    
    var startDate: Date {
        return startAt ?? Date()
    }
    
    var state: VideoTimeline.VideoState {
        return VideoTimeline.VideoState(rawValue: status.rawValue) ?? .active
    }
    
    var previewDate: String {
        if let date = previewDateString {
            return date
        }
        
        guard let date = NSCalendar.current.date(byAdding: .minute, value: -1, to: Date()) else {
            return ""
        }
        let dateStr = DateFormatter.yearMonthDay.string(from: date)
        self.previewDateString = dateStr
        return dateStr
    }
}

extension VMSCamera: VMSAnalyticType {
    
    public func getId() -> Int {
        return id
    }
    
    public func typeName() -> String {
        return name ?? ""
    }
    
    public func titleName() -> String {
        return name ?? ""
    }
}

public final class VMSCameraServices: Decodable {
    
    public var ptz: Bool?
    public var motionDetect: Bool?
    
    public init(ptz: Bool? = nil, motionDetect: Bool? = nil) {
        self.ptz = ptz
        self.motionDetect = motionDetect
    }
}

public final class VMSArchiveRanges: Decodable {
   
    public var duration: CGFloat?
    public var from: CGFloat?
    public var end: CGFloat?
    
    public func rangeEnd() -> CGFloat? {
        if let end = end {
            return end
        }
        return (from ?? 0) + (duration ?? 0)
    }
    
    public init(duration: CGFloat? = nil, from: CGFloat? = nil, end: CGFloat? = nil) {
        self.duration = duration
        self.from = from
        self.end = end
    }
}


public final class VMSCameraPreview: Decodable {
    
    public let preview: String?
    public var status: VMSUserStatusType?
    public var cameraId: Int!
    
    enum CodingKeys: String, CodingKey {
        case preview
        case cameraId
        case status
    }
    
    public init(preview: String?, status: VMSUserStatusType? = nil, cameraId: Int) {
        self.preview = preview
        self.status = status
        self.cameraId = cameraId
    }
}
