import Foundation

/// Measure execution time for a piece of code
public func measure(fileName: String = #file,
                    function: String =  #function,
                    line: Int = #line,
                    _ closure: () -> ()) {
    let startTime = Date()
    closure()
    let endTime = Date()

    let difference = endTime.timeIntervalSince(startTime)
    if difference < .millisecond {
        log("Less than 1ms", fileName: fileName, function: function, line: line)
    } else if difference < .second {
        let ms = Int(difference*1000)
        log("\(ms)ms", fileName: fileName, function: function, line: line)
    } else {
        log(String(format: "%.2fs", difference), fileName: fileName, function: function, line: line)
    }
}

