//
//  Utils.swift
//  BaseSwiftProject
//
//  Created by Grimbolt on 07.01.2017.
//
//

import Foundation

public func PRINT(_ text: String) {
    if Settings.DEBUG_LOGS_ENABLED {
        print(text)
    }
}

public func LOG(_ format: String, args:CVarArg...) {
    if Settings.DEBUG_LOGS_ENABLED {
        NSLog(format, args)
    }
}
