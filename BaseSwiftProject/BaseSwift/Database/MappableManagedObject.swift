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

public struct PrimaryKey {
    public var mapKey: String
    public var objectKey: String
    
    public init(mapKey: String, objectKey: String) {
        self.mapKey = mapKey
        self.objectKey = objectKey
    }
}

open class MappableManagedObject: NSManagedObject, StaticMappable {
    
    open class func primaryKey() -> PrimaryKey? {
        return nil
    }
    
    override public init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    open static func objectForMapping(map: Map) -> BaseMappable? {
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
        return MappableManagedObject.init(entity: entity!, insertInto: DatabaseHelper.sharedInstance.backgroundContext)
    }

    open func mapping(map: Map) {
    }

}
