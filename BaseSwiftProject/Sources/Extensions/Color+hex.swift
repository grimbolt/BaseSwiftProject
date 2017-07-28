import UIKit

public extension UIColor {
    public convenience init?(hexString: String) {
        var hex: String
        if hexString.hasPrefix("#") {
            let index = hexString.characters.index(hexString.startIndex, offsetBy: 1)
            hex = hexString.substring(from: index)
        } else {
            hex = hexString
        }
        hex = hex.uppercased()

        let notHexDigits = CharacterSet.decimalDigits.union(["A", "B", "C", "D", "E", "F"]).inverted
        if let _ = hex.rangeOfCharacter(from: notHexDigits) {
            return nil
        }

        var red: CGFloat   = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat  = 0.0
        var alpha: CGFloat = 1.0

        let scanner = Scanner(string: hex)
        var hexValue: CUnsignedLongLong = 0
        if scanner.scanHexInt64(&hexValue) {
            switch (hex.characters.count) {
            case 3:
                red   = CGFloat((hexValue & 0xF00) >> 8)       / 15.0
                green = CGFloat((hexValue & 0x0F0) >> 4)       / 15.0
                blue  = CGFloat(hexValue & 0x00F)              / 15.0
            case 4:
                red   = CGFloat((hexValue & 0xF000) >> 12)     / 15.0
                green = CGFloat((hexValue & 0x0F00) >> 8)      / 15.0
                blue  = CGFloat((hexValue & 0x00F0) >> 4)      / 15.0
                alpha = CGFloat(hexValue & 0x000F)             / 15.0
            case 6:
                red   = CGFloat((hexValue & 0xFF0000) >> 16)   / 255.0
                green = CGFloat((hexValue & 0x00FF00) >> 8)    / 255.0
                blue  = CGFloat(hexValue & 0x0000FF)           / 255.0
            case 8:
                red   = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
                green = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
                blue  = CGFloat((hexValue & 0x0000FF00) >> 8)  / 255.0
                alpha = CGFloat(hexValue & 0x000000FF)         / 255.0
            default:
                // Invalid RGB string, number of characters after '#' should be either 3, 4, 6 or 8
                return nil
            }
        } else {
            // "Scan hex error
            return nil
        }

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    public var hexString: String {
        let comps = self.cgColor.components!
        let compsCount = self.cgColor.numberOfComponents
        let r: Int
        let g: Int
        var b: Int

        if compsCount == 4 { // RGBA
            r = Int(comps[0] * 255)
            g = Int(comps[1] * 255)
            b = Int(comps[2] * 255)
        } else { // Grayscale
            r = Int(comps[0] * 255)
            g = Int(comps[0] * 255)
            b = Int(comps[0] * 255)
        }
        var hexString = "#"
        hexString += String(format: "%02X%02X%02X", r, g, b)

        return hexString
    }
}
