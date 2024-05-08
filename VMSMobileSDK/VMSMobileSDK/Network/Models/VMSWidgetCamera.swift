
import UIKit

public final class VMSWidgetCamera: Decodable, Hashable {
    
    public enum StatusType: String, Decodable {
        case active
        case inactive
        case partial
        case empty
        case initial
    }
    
    public enum UserStatus: String, Decodable {
        case active
        case blocked
    }

    public var id: Int!
    public var name: String?
    public var previewDateString: String?
    public var status: StatusType? = .active
    public var userStatus: UserStatus? = .active
    public var isFavorite: Bool?
    private var imageData: Data?
    
    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: VMSWidgetCamera, rhs: VMSWidgetCamera) -> Bool {
        return lhs.id == rhs.id
    }
    
    public init(id: Int) {
        self.id = id
    }
}

extension VMSWidgetCamera {
    
    public var previewDate: String {
        if let date = previewDateString {
            return date
        }
        
        guard let date = NSCalendar.current.date(byAdding: .minute, value: -1, to: Date()) else {
            return ""
        }
        let dateStr = DateFormatter.serverUTC.string(from: date)
        self.previewDateString = dateStr
        return dateStr
    }
    
    public func setImage(_ image: UIImage) {
        self.imageData = image.pngData()
    }
    
    public func getImage() -> UIImage? {
        guard let data = imageData else {
            return nil
        }
        return UIImage(data: data)
    }
}
