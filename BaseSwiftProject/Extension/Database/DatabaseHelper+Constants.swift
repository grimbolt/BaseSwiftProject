//
//  DatabaseHelper+Constants.swift
//  BaseSwiftProject
//
//  Created by Grimbolt on 16.01.2017.
//
//

import Foundation

private protocol FakeDatabaseConstantsProtocol {}

extension DatabaseHelper: FakeDatabaseConstantsProtocol {
    
    static let DATABASE_NAME = "BaseSwiftProject"
    static let DATABASE_FILE_NAME = "\(DATABASE_NAME).sqlite"
    static let sharedInstance = DatabaseHelper()

}
