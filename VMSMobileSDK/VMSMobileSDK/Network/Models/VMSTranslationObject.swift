
import Foundation

public typealias VMSTranslationDict = [String : String]

public final class VMSTranslationObject : Codable {
    
    public var language: String?
    public var revision: Int?
    public var json: VMSTranslationDict?
    
    public init(lang: String) {
        revision = 0
        json = VMSTranslationDict()
        language = lang
    }
}
