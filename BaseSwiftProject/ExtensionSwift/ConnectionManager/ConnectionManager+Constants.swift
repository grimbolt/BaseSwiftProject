//
//  ConnectionManager+Constants.swift
//  BaseSwiftProject
//
//  Created by Grimbolt on 07.01.2017.
//
//

import Foundation

private protocol FakeConnectionConstantsProtocol {}

extension ConnectionManager: FakeConnectionConstantsProtocol {
    static let BASE_URL = "https://pastebin.com"
    static let SAMPLE_LOGIN_URL = BASE_URL + "/api/api_login.php"
    static let SAMPLE_POST_URL = BASE_URL + "/api/api_raw.php"
    
    static let API_DEV_KEY = "********************************"
    static let API_USER_NAME = "**********"
    static let API_USER_PASSWORD = "**********"
}
