
import Foundation
import UIKit
import CoreHaptics

extension UIColor {
    
    static var main: UIColor { return UIColor(hex: 0x2F67FD) }
    
    static var mainGrey: UIColor { return UIColor(hex: 0x5A6072) }
    
    static var playerYellow: UIColor { return UIColor(hex: 0xE7C410) }
    
    static var playerBlue: UIColor { return UIColor(hex: 0x2F67FD) }
    
    static var buttonNormal: UIColor { return .main }
    static var buttonDisabled: UIColor { return UIColor(hex: 0xC8CCD0) }
    static var markDetect: UIColor { return UIColor(hex: 0x2CA329) }
    
    convenience init(red: Int, green: Int, blue: Int, alpha: Float = 1.0) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: CGFloat(alpha))
    }
    
    convenience init(hex: Int, alpha: Float = 1.0) {
        self.init(
            red: (hex >> 16) & 0xFF,
            green: (hex >> 8) & 0xFF,
            blue: hex & 0xFF,
            alpha: alpha
        )
    }
}

extension NSAttributedString.Key {
    static let dateAtributeName = NSAttributedString.Key(rawValue: "date")
    static let timeAtributeName = NSAttributedString.Key(rawValue: "time")
}

public func isSmallIPhone() -> Bool {
    switch UIScreen.main.nativeBounds.height {
    case 1136:
        return true
    default:
        return false
    }
}

public extension UIDevice {
    
    static func vibrate(isAllowed: Bool) {
        if isAllowed && isHapticsSupported {
            if #available(iOS 10.0, *) {
                let generator = UIImpactFeedbackGenerator(style: .light)
                if #available(iOS 13.0, *) {
                    generator.impactOccurred(intensity: 0.7)
                } else {
                    // for ios 12 and lower
                    generator.impactOccurred()
                }
            }
        }
    }
    
    static func selectionVibrate(isAllowed: Bool) {
        if isAllowed && isHapticsSupported {
            if #available(iOS 10.0, *) {
                let generator = UISelectionFeedbackGenerator()
                generator.prepare()
                generator.selectionChanged()
            }
        }
    }
    
    static func successVibration(isAllowed: Bool) {
        if isAllowed && isHapticsSupported {
            if #available(iOS 10.0, *) {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
    
    static func warningVibration(isAllowed: Bool) {
        if isAllowed && isHapticsSupported {
            if #available(iOS 10.0, *) {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
            }
        }
    }
    
    static var modelIdentifier: String {
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }
    
    static var isHapticsSupported : Bool {
        if #available(iOS 13.0, *) {
            let hapticCapability = CHHapticEngine.capabilitiesForHardware()
            let supportsHaptics = hapticCapability.supportsHaptics
            return supportsHaptics
        } else {
            // assuming that iPads and iPods don't have a Taptic Engine
            if !modelIdentifier.contains("iPhone") {
                return false
            }
            
            // e.g. will equal to "9,5" for "iPhone9,5"
            let subString = String(modelIdentifier[modelIdentifier.index(modelIdentifier.startIndex, offsetBy: 6)..<modelIdentifier.endIndex])
            
            // will return true if the generationNumber is equal to or greater than 9
            if let generationNumberString = subString.components(separatedBy: ",").first,
                let generationNumber = Int(generationNumberString),
                generationNumber >= 9 {
                return true
            }
            return false
        }
    }
}

extension UIView {
    func sizeAnchor(size: CGSize) {
        widthAnchor.constraint(equalToConstant: size.width).isActive = true
        heightAnchor.constraint(equalToConstant: size.height).isActive = true
    }
}

extension UIImageView {
    
    func setTintColor(_ color: UIColor = .main) {
        self.image = self.image?.withRenderingMode(.alwaysTemplate)
        self.tintColor = color
    }
}

extension Date {
    
    func tenMinAfter() -> Date {
        return Calendar.current.date(byAdding: .minute, value: 10, to: self) ?? Date()
    }
    
    func tenMinBefore() -> Date {
        return Calendar.current.date(byAdding: .minute, value: -10, to: self) ?? Date()
    }
}

extension Array {
    
    mutating func remove(at indexes: [Int]) {
        var lastIndex: Int? = nil
        for index in indexes.sorted(by: >) {
            guard lastIndex != index else {
                continue
            }
            remove(at: index)
            lastIndex = index
        }
    }
}

extension UIViewController {
    
    var deviceHasNotch: Bool {
        if #available(iOS 11.0, *) {
            let bottom = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
            return bottom > 0
        } else {
            return false
        }
    }
}

extension String {
    
    func setLenght(to maxCount: Int) -> String {
        if self.count > maxCount {
            var s = self
            let needToDelete = s.count - maxCount
            s.removeLast(needToDelete)
            s.append("...")
            return s
        } else {
            return self
        }
    }
}

extension DateFormatter {
    
    /**
     yyyy-MM-dd HH:mm:ss
     */
    static var yearMonthDay: DateFormatter {
        get {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return dateFormatter
        }
    }
    
    /**
     dd.MM.YYYY
     */
    static var dayMonthYear: DateFormatter {
        get {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.YYYY"
            return dateFormatter
        }
    }
}

extension UIStackView {
    func removeAllArrangedSubviews()  {
        arrangedSubviews.forEach { (view) in
            view.removeFromSuperview()
            NSLayoutConstraint.deactivate(view.constraints)
        }
    }
}

extension UIImage {
    func imageWithColor(_ color: UIColor = .main) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        color.setFill()

        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.setBlendMode(CGBlendMode.normal)

        let rect = CGRect(origin: .zero, size: CGSize(width: self.size.width, height: self.size.height))
        context?.clip(to: rect, mask: self.cgImage!)
        context?.fill(rect)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
    
    func imageWithSize(_ size: CGSize) -> UIImage {
        
        var scaledImageRect = CGRect.zero
        let aspectWidth: CGFloat = size.width / self.size.width
        let aspectHeight: CGFloat = size.height / self.size.height
        let aspectRatio : CGFloat = min(aspectWidth, aspectHeight)
        
        scaledImageRect.size.width = self.size.width * aspectRatio
        scaledImageRect.size.height = self.size.height * aspectRatio
        scaledImageRect.origin.x = (size.width - scaledImageRect.size.width) / 2.0
        scaledImageRect.origin.y = (size.height - scaledImageRect.size.height) / 2.0
        
        UIGraphicsBeginImageContextWithOptions(size, true, 0)
        
        self.draw(in: scaledImageRect)
        
        guard let scaledImage = UIGraphicsGetImageFromCurrentImageContext() else {return UIImage()}
        UIGraphicsEndImageContext()
        
        return scaledImage
        
    }
}

extension UINavigationItem {
    func clearBackTitle() {
        self.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItem.Style.plain, target: nil, action: nil)
    }
}
