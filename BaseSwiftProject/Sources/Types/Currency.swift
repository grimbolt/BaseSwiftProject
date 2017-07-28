import Foundation

/// A type that can hold value in PLN.
///
/// Example usage:
///     // Initializing currency from literal as 6zł 55gr
///     let applePrice: Currency = 6.55
///
///     // Oranges cost 1zł 28gr
///     let orangePrice = Currency(gr: 128)
///
///     // You can multiply it by a scalar, or add them together
///     let cost = 3*applePrice + 8*orangePrice
///
///     // Prints "29,89 zł"
///     print(cost)
///
public struct Currency: ExpressibleByFloatLiteral, CustomStringConvertible {
    public typealias FloatLiteralType = Double

    public var gr: Int
    public var zł: Double {
        get {
            return Double(self.gr)/100
        }
        set {
            self.gr = Int((newValue*100).rounded(.toNearestOrAwayFromZero))
        }
    }

    public init(floatLiteral value: Currency.FloatLiteralType) {
        self.init(zł: value)
    }

    public init(gr: Int) {
        self.gr = gr
    }

    public init?(gr: String) {
        if let grInt = Int(gr) {
            self.gr = grInt
        } else {
            return nil
        }
    }

    public init(zł: Double) {
        self.gr = 0
        self.zł = zł
    }


    public init?(zł: String) {
        self.gr = 0
        if let złDouble = Double(zł) {
            self.zł = złDouble
        } else {
            return nil
        }
    }

    public var stringValue: String {
        let numberString = String(format:"%.2f", self.zł)
            .replacingOccurrences(of: ".", with: ",")
        return numberString+" zł"
    }

    public var description: String {
        return self.stringValue
    }
}

public extension Currency {
    public static func +(lhs: Currency, rhs: Currency) -> Currency {
        return Currency(gr: lhs.gr+rhs.gr)
    }

    static func -(lhs: Currency, rhs: Currency) -> Currency {
        return Currency(gr: lhs.gr-rhs.gr)
    }

    static func *(lhs: Currency, rhs: Double) -> Currency {
        return Currency(gr: Int(Double(lhs.gr)*rhs))
    }

    static func *(lhs: Double, rhs: Currency) -> Currency {
        return Currency(gr: Int(lhs*Double(rhs.gr)))
    }
}
