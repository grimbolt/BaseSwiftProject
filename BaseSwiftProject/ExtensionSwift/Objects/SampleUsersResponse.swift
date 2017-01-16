//
//  SampleUsersResponse.swift
//  BaseSwiftProject
//
//  Created by Grimbolt on 09.01.2017.
//
//

import Foundation
import ObjectMapper

class SampleUsersResponse: Mappable {
    var results: [SampleUser]?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        results <- map["results"]
    }
}
