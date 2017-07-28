import Foundation

/// Print string with additional location information.
public func log(_ text: String,  fileName: String = #file, function: String =  #function, line: Int = #line) {
    print("[\(fileName.components(separatedBy: "/").last ?? "???"):\(line):\(function)]")
    print("->", text)
}

