
import Foundation
import UIKit

public final class VMSCaptcha: Decodable {
    
    public var key: String!
    public var img: String!
    public var ttl: Int!
    
    public func getImage() -> UIImage? {
        var imageData = img
        let results = imageData!.matches(for: "data:image\\/([a-zA-Z]*);base64,")
        if results.count > 0 {
            imageData = imageData!.replacingOccurrences(of: results[0], with: "")
        }
        if let decodedData = Data(base64Encoded: imageData!, options: .ignoreUnknownCharacters) {
            return UIImage(data: decodedData)
        }
        return nil
    }
    
    public init(key: String, img: String, ttl: Int) {
        self.key = key
        self.img = img
        self.ttl = ttl
    }
}
