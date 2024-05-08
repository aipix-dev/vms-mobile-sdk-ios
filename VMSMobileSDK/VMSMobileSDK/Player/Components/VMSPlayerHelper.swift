
import Foundation

class VMSLocalization {
    
    static func getCurrentLocale(language: String) -> Locale {
        let locale: String = ("\(language)-\(language.uppercased())")
        return Locale(identifier: locale)
    }
    
}
