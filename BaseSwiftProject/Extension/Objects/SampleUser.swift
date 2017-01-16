//
//  SampleResponse.swift
//  BaseSwiftProject
//
//  Created by Grimbolt on 07.01.2017.
//
//

import Foundation
import ObjectMapper
import CoreData

@objc(SampleUser)
class SampleUser: MappableManagedObject {
    
    @NSManaged var gender: String?
    @NSManaged var nameFirst: String?
    @NSManaged var nameLast: String?
    @NSManaged var email: String?
    @NSManaged var id: String
    @NSManaged var picture: String?
    
    override class func primaryKey() -> PrimaryKey? {
        return PrimaryKey(mapKey: "login.md5", objectKey: "id")
    }
    
    override func mapping(map: Map) {
        if gender != map["gender"].currentValue as? String {
            gender <- map["gender"]
        }
        if nameFirst != map["name.first"].currentValue as? String {
            nameFirst <- map["name.first"]
        }
        if nameLast != map["name.last"].currentValue as? String {
            nameLast <- map["name.last"]
        }
        if email != map["email"].currentValue as? String {
            email <- map["email"]
        }
        if id != map["login.md5"].currentValue as? String {
            id <- map["login.md5"]
        }
        if picture != map["picture.thumbnail"].currentValue as? String {
            picture <- map["picture.thumbnail"]
        }
    }
}
