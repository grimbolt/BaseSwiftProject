import Foundation

public extension TimeInterval {
    public static let millisecond = 0.001 as TimeInterval
    public static let second = 1 as TimeInterval
    public static let minute = 60 * .second
    public static let hour = 60 * .minute
    public static let day = 24 * .hour
    public static let week = 7 * .day
}

