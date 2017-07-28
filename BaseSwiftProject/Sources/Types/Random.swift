import Foundation

/// Various randomness sources
public enum Random {

    /// Returns random `UInt32`
    public static func uint32() -> UInt32 {
        return arc4random()
    }

    /// Returns random `Int` between `0` and `(2**32)-1`
    public static func int() -> Int {
        return Int(arc4random())
    }

    /**
     Returns random `Int` in range
     - parameters:
     - from: First possible value
     - to: 1 higher than the highest possible value
     */
    public static func int(from: Int = 0, to: Int) -> Int {
        guard from < to else {
            fatalError("from needs to be lower than to")
        }
        let range = to-from
        return (Random.int()%range)+from
    }

    /// Returns random `Double` between `0` and `1`
    public static func double() -> Double {
        return Double(Random.uint32())/Double(UInt32.max)
    }

    /**
     Returns random `Double` in range
     - parameters:
     - from: Start of the range
     - to: End of the range
     */
    public static func double(from: Double = 0, to: Double) -> Double {
        guard from < to else {
            fatalError("from needs to be lower than to")
        }
        let range = to-from
        return Random.double()*range + from
    }
    
    /// Returns random `Bool`
    public static func bool() -> Bool {
        return Random.uint32() % 2 == 1
    }
}
