import Foundation

public extension String {
    public func localized() -> String {
        return NSLocalizedString(self, comment: "")
    }
}
