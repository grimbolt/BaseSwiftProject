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

    private static let lock = NSLock()
    
    open class func primaryKey() -> PrimaryKey? {
        return nil
    }

    open class func primaryKeys() -> [PrimaryKey] {
        return [PrimaryKey]()
    }
    
    override public init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    open static func objectForMapping(map: Map) -> BaseMappable? {
        var object: MappableManagedObject? = nil

        DatabaseHelper.sharedInstance.backgroundContext.performAndWait {
            MappableManagedObject.lock.lock() ; defer { MappableManagedObject.lock.unlock() }
            
            let className = NSStringFromClass(self)

            var predicates = [NSPredicate]()
            
            if let primaryKey = primaryKey() {
                if let value = map[primaryKey.mapKey].currentValue as? String {
                    predicates.append(NSPredicate(format: primaryKey.objectKey + " = %@", value))
                } else if let value = map[primaryKey.mapKey].currentValue {
                    predicates.append(NSPredicate(format: primaryKey.objectKey + " = \(value)"))
                } else {
                    predicates.append(NSPredicate(format: primaryKey.objectKey + " = nil OR " + primaryKey.objectKey + " = 0 OR " + primaryKey.objectKey + " = \"\""))
                }
            }
            
            for primaryKey in primaryKeys() {
                if let value = map[primaryKey.mapKey].currentValue as? String {
                    predicates.append(NSPredicate(format: primaryKey.objectKey + " = %@", value))
                } else if let value = map[primaryKey.mapKey].currentValue {
                    predicates.append(NSPredicate(format: primaryKey.objectKey + " = \(value)"))
                } else {
                    predicates.append(NSPredicate(format: primaryKey.objectKey + " = nil OR " + primaryKey.objectKey + " = 0 OR " + primaryKey.objectKey + " = \"\""))
                }
            }

            if predicates.count > 0 {
                let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
                object = DatabaseHelper.sharedInstance.fetch(entityName: className, predicate: predicate, sync: false).first as? MappableManagedObject
            }
            
            if object == nil {
                let entity = NSEntityDescription.entity(forEntityName: className, in: DatabaseHelper.sharedInstance.backgroundContext)
                object = MappableManagedObject.init(entity: entity!, insertInto: DatabaseHelper.sharedInstance.backgroundContext)
            }
        }
        
        return object
    }

    public func mapping(map: Map) {
        DatabaseHelper.sharedInstance.backgroundContext.performAndWait { [weak self] in
            self?.coreDataMapping(map: map)
        }
    }

    open func coreDataMapping(map: Map) {
    }

}
