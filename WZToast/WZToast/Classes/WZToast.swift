// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit

@MainActor
@available(iOS 13.0, *)
final public class WZToast {
    
    @MainActor
    public struct Style {
        public var backgroundColor : UIColor
        public var textColor : UIColor
        public var font : UIFont
        public var icon : UIImage?
        
        public init(backgroundColor: UIColor, textColor: UIColor, font: UIFont, icon: UIImage? = nil) {
            self.backgroundColor = backgroundColor
            self.textColor = textColor
            self.font = font
            self.icon = icon
        }
        
        public static var info = Style(backgroundColor: UIColor.init(white: 0, alpha: 1), textColor: UIColor.white, font: UIFont.systemFont(ofSize: 14))
        public static var success = Style(backgroundColor: UIColor(hexString: "#72DD4D")!, textColor: UIColor.white, font: UIFont.systemFont(ofSize: 14), icon: UIImage.getImageFromBundle(name: "success@3x.png"))
        public static var fail = Style(backgroundColor: UIColor(hexString: "#E14747")!, textColor: UIColor.white, font: UIFont.systemFont(ofSize: 14), icon: UIImage.getImageFromBundle(name: "fail@3x.png"))
        public static var warn = Style(backgroundColor: UIColor(hexString: "#F7C11F")!, textColor: UIColor.white, font: UIFont.systemFont(ofSize: 14), icon: UIImage.getImageFromBundle(name: "warning@3x.png"))
    }
    
    public enum Duration {
        case short
        case average
        case custom(TimeInterval)
        
        var length: TimeInterval {
            switch self {
            case .short: return 1
            case .average: return 2.5
            case .custom(let timeInterval):
                return timeInterval
            }
        }
    }
    
    public enum Location {
        case top
        case bottom
    }
    
    public static let shared = WZToast()
    private let animationDuration = 0.25
    
    private lazy var mainWindow = {
        if let window = UIApplication.shared.delegate?.window {
            return window
            
        } else {
            let window = UIApplication.shared.windows.filter { $0.isKeyWindow }.first
            return window
        }
    }()
    private init() {
        
    }
    
    public func showInfo(message: String, location: Location = .bottom, duration: Duration = .average) {
        show(message: message, style: .info, location: location, duration: duration)
    }
    
    public func showSuccess(message: String, location: Location = .bottom, duration: Duration = .average) {
        show(message: message, style: .success, location: location, duration: duration)
    }
    
    public func showFail(message: String, location: Location = .bottom, duration: Duration = .average) {
        show(message: message, style: .fail, location: location, duration: duration)
    }
    
    public func showWarning(message: String, location: Location = .bottom, duration: Duration = .average) {
        show(message: message, style: .warn, location: location, duration: duration)
    }
    
    public func show(message: String, style: Style?, location: Location = .bottom, duration: Duration = .average) {
        var s = style
        if s == nil {
            s = .info
        }
        
        if Thread.current.isMainThread {
            _safeShow(message: message, style: s!, location: location, duration: duration)
        } else {
            MainActor.assumeIsolated {
                _safeShow(message: message, style: s!, location: location, duration: duration)
            }
        }
    }
    
    private func _safeShow(message: String, style: Style, location: Location, duration: Duration) {
        let toast = WZToastView(message: message, style: style)
        var originY = CGFloat()
        var targetY = CGFloat()
        switch location {
        case .top:
            originY = -toast.frame.size.height
            targetY = (mainWindow?.safeAreaInsets.top ?? 20) + 12
        case .bottom:
            originY = mainWindow?.frame.maxY ?? UIScreen.main.bounds.maxY
            targetY = (mainWindow?.frame.maxY ?? UIScreen.main.bounds.maxY) - ((mainWindow?.safeAreaInsets.bottom ?? 0) + 12) - toast.frame.height
        }
        toast.frame.origin = CGPoint(x: ((mainWindow?.frame.width ?? UIScreen.main.bounds.width) - toast.frame.width) / 2, y: originY)
        mainWindow?.addSubview(toast)
        
        UIView.animate(withDuration: animationDuration) {
            toast.frame.origin.y = targetY
            
        } completion: { isFinished in
            DispatchQueue.main.asyncAfter(deadline: .now() + duration.length) { [weak toast] in
                if toast != nil {
                    UIView.animate(withDuration: self.animationDuration) {
                        toast?.frame.origin.y = originY
                        
                    } completion: { _ in
                        toast?.removeFromSuperview()
                    }
                }
            }
        }
    }
}

private extension UIImage {
    static func getImageFromBundle(name: String) -> UIImage? {
        guard let path = Bundle(for: WZToast.self).path(forResource: "WZToastBundle", ofType: "bundle") else {
            return nil
        }
        let bundle = Bundle(path: path)
        return UIImage(named: name, in:  bundle, compatibleWith: nil)
    }
}

@available(iOS 13.0, *)
class WZToastView : UIView {
    private lazy var imageView : UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var textLabel : UILabel = {
        let textLabel = UILabel()
        textLabel.numberOfLines = 0
        return textLabel
    }()
    
    private let padding = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(message: String, style: WZToast.Style) {
        self.init()
        backgroundColor = style.backgroundColor
        clipsToBounds = true
        layer.cornerRadius = (ceil(style.font.lineHeight) + padding.top + padding.bottom) / 2
        
        addSubview(textLabel)
        addSubview(imageView)
        
        textLabel.text = message
        textLabel.font = style.font
        textLabel.textColor = style.textColor
        if let icon = style.icon {
            imageView.image = icon
            imageView.isHidden = false
        } else {
            imageView.isHidden = true
        }
        
        var textMaxWidth = UIScreen.main.bounds.width - (24*2) - (padding.left + padding.right);
        if !imageView.isHidden {
            textMaxWidth -= 16 + 8
        }
        
        let textSize = textLabel.text!.size(font: textLabel.font, maxSize: CGSize(width: textMaxWidth, height: 0))
        
        bounds = CGRect(x: 0, y: 0, width: 0, height: 0)
        if imageView.isHidden {
            textLabel.frame = CGRect(x: padding.left, y: padding.top, width: textSize.width, height: textSize.height)
            bounds.size = CGSize(width: textSize.width + padding.left + padding.right, height: textSize.height + padding.top + padding.bottom)
        } else {
            imageView.frame = CGRect(x: padding.left, y: 0, width: 16, height: 16)
            textLabel.frame = CGRect(x: imageView.frame.maxX + 8, y: padding.top, width: textSize.width, height: textSize.height)
            bounds.size = CGSize(width: textLabel.frame.maxX + padding.right, height: textLabel.frame.maxY + padding.bottom)
            imageView.frame.origin.y = (bounds.height - imageView.frame.height) / 2
        }
    }
}

private extension String {
    func size(font: UIFont, maxSize: CGSize) -> CGSize {
        var size = maxSize
        if size.width == 0 {
            size.width = Double.greatestFiniteMagnitude
        }
        if size.height == 0 {
            size.height = Double.greatestFiniteMagnitude
        }
        
        let attr = NSAttributedString.init(string: self, attributes: [
            .font: font
        ])
        var rect = attr.boundingRect(with: size, options: .usesLineFragmentOrigin, context: nil)
        rect.size.width = ceil(rect.width)
        rect.size.height = ceil(rect.height)
        return rect.size
    }
}

private extension Int64 {
    func duplicate4bits() -> Int64 {
        return (self << 4) + self
    }
}

private extension UIColor {
    private convenience init?(hex3: Int64, alpha: Float) {
        self.init(red:   CGFloat( ((hex3 & 0xF00) >> 8).duplicate4bits() ) / 255.0,
                  green: CGFloat( ((hex3 & 0x0F0) >> 4).duplicate4bits() ) / 255.0,
                  blue:  CGFloat( ((hex3 & 0x00F) >> 0).duplicate4bits() ) / 255.0,
                  alpha: CGFloat(alpha))
    }

    private convenience init?(hex4: Int64, alpha: Float?) {
        self.init(red:   CGFloat( ((hex4 & 0xF000) >> 12).duplicate4bits() ) / 255.0,
                  green: CGFloat( ((hex4 & 0x0F00) >> 8).duplicate4bits() ) / 255.0,
                  blue:  CGFloat( ((hex4 & 0x00F0) >> 4).duplicate4bits() ) / 255.0,
                  alpha: alpha.map(CGFloat.init(_:)) ?? CGFloat( ((hex4 & 0x000F) >> 0).duplicate4bits() ) / 255.0)
    }

    private convenience init?(hex6: Int64, alpha: Float) {
        self.init(red:   CGFloat( (hex6 & 0xFF0000) >> 16 ) / 255.0,
                  green: CGFloat( (hex6 & 0x00FF00) >> 8 ) / 255.0,
                  blue:  CGFloat( (hex6 & 0x0000FF) >> 0 ) / 255.0, alpha: CGFloat(alpha))
    }

    private convenience init?(hex8: Int64, alpha: Float?) {
        self.init(red:   CGFloat( (hex8 & 0xFF000000) >> 24 ) / 255.0,
                  green: CGFloat( (hex8 & 0x00FF0000) >> 16 ) / 255.0,
                  blue:  CGFloat( (hex8 & 0x0000FF00) >> 8 ) / 255.0,
                  alpha: alpha.map(CGFloat.init(_:)) ?? CGFloat( (hex8 & 0x000000FF) >> 0 ) / 255.0)
    }
    
    convenience init?(hexString: String, alpha: Float? = nil) {
        var hex = hexString
        
        if hex.hasPrefix("#") {
            hex = String(hex[hex.index(after: hex.startIndex)...])
        }

        guard let hexVal = Int64(hex, radix: 16) else {
            self.init()
            return nil
        }

        switch hex.count {
        case 3:
            self.init(hex3: hexVal, alpha: alpha ?? 1.0)
        case 4:
            self.init(hex4: hexVal, alpha: alpha)
        case 6:
            self.init(hex6: hexVal, alpha: alpha ?? 1.0)
        case 8:
            self.init(hex8: hexVal, alpha: alpha)
        default:
            self.init()
            return nil
        }
    }
    
    convenience init?(hex: Int, alpha: Float = 1.0) {
            if (0x000000 ... 0xFFFFFF) ~= hex {
                self.init(hex6: Int64(hex), alpha: alpha)
            } else {
                self.init()
                return nil
            }
        }
        
        convenience init?(argbHex: Int) {
            if (0x00000000 ... 0xFFFFFFFF) ~= argbHex {
                let hex = Int64(argbHex)
                self.init(red: CGFloat( (hex & 0x00FF0000) >> 16 ) / 255.0,
                          green: CGFloat( (hex & 0x0000FF00) >> 8 ) / 255.0,
                          blue:  CGFloat( (hex & 0x000000FF) >> 0 ) / 255.0,
                          alpha: CGFloat( (hex & 0xFF000000) >> 24 ) / 255.0)
            } else {
                self.init()
                return nil
            }
        }
        
        convenience init?(argbHexString: String) {
            var hex = argbHexString

            // Check for hash and remove the hash
            if hex.hasPrefix("#") {
                hex = String(hex[hex.index(after: hex.startIndex)...])
            }
            
            guard hex.count == 8, let hexVal = Int64(hex, radix: 16) else {
                self.init()
                return nil
            }
            self.init(red: CGFloat( (hexVal & 0x00FF0000) >> 16 ) / 255.0,
                      green: CGFloat( (hexVal & 0x0000FF00) >> 8 ) / 255.0,
                      blue:  CGFloat( (hexVal & 0x000000FF) >> 0 ) / 255.0,
                      alpha: CGFloat( (hexVal & 0xFF000000) >> 24 ) / 255.0)
        }
}
