import Foundation
import Dispatch

/// Execute closure on main thread, synchronously
public func onMain(_ closure: () -> ()) {
    if Thread.isMainThread {
        closure()
    } else {
        DispatchQueue.main.sync(execute: closure)
    }
}

