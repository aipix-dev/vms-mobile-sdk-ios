
import Foundation

public final class VMSTimetable: Decodable {
    
    public var days: [VMSDays]?
    public var intervals: [VMSIntervals]?
    
    enum CodingKeys: String, CodingKey {
        case days, intervals
    }
    
    public init(days: [VMSDays]?, intervals: [VMSIntervals]?) {
        self.days = days
        self.intervals = intervals
    }
    
    func toJSON() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        dictionary[CodingKeys.days.rawValue] = days?.map({$0.toJSON() })
        dictionary[CodingKeys.intervals.rawValue] = intervals?.map({$0.toJSON() })
        
        return dictionary
    }
}

public final class VMSDays: Decodable {
    
    public enum DayOfWeek: String, Codable {
        case monday
        case tuesday
        case wednesday
        case thursday
        case friday
        case saturday
        case sunday
        case sameEveryDay = "same_every_day"
    }
    
    public var type: DayOfWeek?
    public var from: String?
    public var to: String?
    
    enum CodingKeys: String, CodingKey {
        case type, from, to
    }
    
    public init(type: DayOfWeek?, from: String?, to: String?) {
        self.type = type
        self.from = from
        self.to = to
    }
    
    func toJSON() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        dictionary[CodingKeys.type.rawValue] = type?.rawValue
        dictionary[CodingKeys.from.rawValue] = from
        dictionary[CodingKeys.to.rawValue] = to
        
        return dictionary
    }
}

public final class VMSIntervals: Decodable {
    
    public var from: String?
    public var to: String?
    
    enum CodingKeys: String, CodingKey {
        case from, to
    }
    
    public init(from: String?, to: String?) {
        self.from = from
        self.to = to
    }
    
    func toJSON() -> [String: Any] {
        var dictionary: [String: Any] = [:]
        dictionary[CodingKeys.from.rawValue] = from
        dictionary[CodingKeys.to.rawValue] = to
        
        return dictionary
    }
}
