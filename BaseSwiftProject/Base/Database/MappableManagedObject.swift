//
//  MappableManagedObject.swift
//  BaseSwiftProject
//
//  Created by Grimbolt on 11.01.2017.
//
//

import Foundation
import ObjectMapper
import CoreData

class MappableManagedObject: NSManagedObject, StaticMappable {
    
    struct PrimaryKey {
        var mapKey: String
        var objectKey: String
    }

    class func primaryKey() -> PrimaryKey? {
        return nil
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    static func objectForMapping(map: Map) -> BaseMappable? {
        guard let primaryKey = primaryKey() else {
            return nil
        }
        
        let className = NSStringFromClass(self)
        
        if let value = map[primaryKey.mapKey].currentValue {
            if let object = DatabaseHelper.sharedInstance.fetch(entityName: className, format: "\(primaryKey.objectKey) = '\(value)'").first as? MappableManagedObject {
                return object
            }
        }
        
        let entity = NSEntityDescription.entity(forEntityName: className, in: DatabaseHelper.sharedInstance.backgroundContext)
        return SampleUser.init(entity: entity!, insertInto: DatabaseHelper.sharedInstance.backgroundContext)
    }

    public func mapping(map: Map) {
    }

}
