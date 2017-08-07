//
//  DatabaseHelper.swift
//  BaseSwiftProject
//
//  Created by Grimbolt on 07.01.2017.
//
//

import Foundation
import CoreData

public class DatabaseHelper: NSObject {
    
    public static let sharedInstance = DatabaseHelper()
    
    // MARK: - Core Data stack
    
    static let applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.test.Core_Data" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1] as NSURL
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        
        let databaseName = DatabaseHelper.value(forKey: "DATABASE_NAME") as! String
        let modelURL = Bundle.main.url(forResource: databaseName, withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let databaseFileName = DatabaseHelper.value(forKey: "DATABASE_FILE_NAME") as! String
        let url = DatabaseHelper.applicationDocumentsDirectory.appendingPathComponent(databaseFileName)
        let failureReason = "There was an error creating or loading the application's saved data."
        do {
            let options = [NSMigratePersistentStoresAutomaticallyOption: true,
                           NSInferMappingModelAutomaticallyOption: true]
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
        }
        
        return coordinator
    }()
    
    public lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        print("▿ App location:\n\(DatabaseHelper.applicationDocumentsDirectory)\n\n")
        
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    private func saveContext (context: NSManagedObjectContext) {
        context.performAndWait {
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    let nserror = error as NSError
                    NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        }
    }
    
    // MARK: - Core Data background context
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(self.contextDidSaveContext), name: NSNotification.Name.NSManagedObjectContextDidSave, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.appWillTerminate(_:)), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public lazy var backgroundContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.persistentStoreCoordinator = coordinator
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return backgroundContext
    }()
    
    public func saveContext () {
        self.saveContext( context: self.backgroundContext )
    }
    
    func appWillTerminate(_ notification: Notification) {
        saveContext()
    }
    
    func contextDidSaveContext(notification: NSNotification) {
        let sender = notification.object as! NSManagedObjectContext
        if sender === self.managedObjectContext {
            NSLog("******** Saved main Context in this thread")
            self.backgroundContext.perform {
                self.backgroundContext.mergeChanges(fromContextDidSave: notification as Notification)
            }
        } else if sender === self.backgroundContext {
            NSLog("******** Saved background Context in this thread")
            self.managedObjectContext.perform {
                self.managedObjectContext.mergeChanges(fromContextDidSave: notification as Notification)
                self.mergeChangesBugFix(notification)
            }
        } else {
            NSLog("******** Saved Context in other thread")
            self.backgroundContext.perform {
                self.backgroundContext.mergeChanges(fromContextDidSave: notification as Notification)
            }
            self.managedObjectContext.perform {
                self.managedObjectContext.mergeChanges(fromContextDidSave: notification as Notification)
                self.mergeChangesBugFix(notification)
            }
        }
    }
    
    //BUG FIX: When the notification is merged it only updates objects which are already registered in the context.
    //If the predicate for a NSFetchedResultsController matches an updated object but the object is not registered
    //in the FRC's context then the FRC will fail to include the updated object. The fix is to force all updated
    //objects to be refreshed in the context thus making them available to the FRC.
    //Note that we have to be very careful about which methods we call on the managed objects in the notifications userInfo.
    
    private func mergeChangesBugFix(_ notification: NSNotification) {
        if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
            for unsafeManagedObject in updatedObjects {
                do {
                    let manangedObject = try self.managedObjectContext.existingObject(with: unsafeManagedObject.objectID)
                    self.managedObjectContext.refresh(manangedObject, mergeChanges: true)
                } catch { }
            }
        }
    }

    // MARK: - Core Data methods
    
    public func fetch(entityName: String, format: String = "", sync:Bool = true) -> [NSManagedObject] {
        let predicate: NSPredicate
        if format != "" {
            predicate = NSPredicate(format: format)
        } else {
            predicate = NSPredicate(value: true)
        }
        
        return self.fetch(entityName: entityName, predicate: predicate, sync: sync)
    }
    
    public func fetch(entityName: String, predicate: NSPredicate, sortDescriptions: [NSSortDescriptor]? = nil, sync:Bool = true) -> [NSManagedObject] {
        var objects: [NSManagedObject] = [NSManagedObject]()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        
        fetchRequest.predicate = predicate
        
        fetchRequest.sortDescriptors = sortDescriptions
        
        func _fetch(helper: DatabaseHelper?) {
            do {
                let results = try helper?.backgroundContext.fetch(fetchRequest)
                objects += results as! [NSManagedObject]
            } catch let error as NSError {
                print("Could not fetch \(error), \(error.userInfo)")
            }
        }
        
        if sync {
            backgroundContext.performAndWait { [weak self] in
                _fetch(helper: self)
            }
        } else {
            _fetch(helper: self)
        }
        
        return objects;
    }
    
    public func fetchCount(entityName: String, format: String = "") -> Int? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        if format != "" {
            fetchRequest.predicate = NSPredicate(format: format)
        }
        
        var count:Int?
        
        backgroundContext.performAndWait { [weak self] in
            do {
                count = try self?.backgroundContext.count(for: fetchRequest)
            } catch let error as NSError {
                print("Could not fetch \(error), \(error.userInfo)")
            }
        }
        
        return count
    }
    
    func delete(entityName: String, format: String = "") {
        let objects: [NSManagedObject] = fetch(entityName: entityName, format: format)
        for object in objects {
            backgroundContext.perform { [weak self] in
                self?.backgroundContext.delete(object)
            }
        }
    }
    
    func createFetchedResultController(_ entityName: String, sortDescriptor: [NSSortDescriptor]?, predicate: NSPredicate?) -> NSFetchedResultsController<NSFetchRequestResult>? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        if let sortDescriptor = sortDescriptor {
            fetchRequest.sortDescriptors = sortDescriptor
        } else {
            fetchRequest.sortDescriptors = []
        }
        if let predicate = predicate {
            fetchRequest.predicate = predicate
        }
        
        var fetchedResultController: NSFetchedResultsController<NSFetchRequestResult>?
        managedObjectContext.performAndWait( { [weak self] in
            guard let strongSelf = self else {
                return
            }
            fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: strongSelf.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        })
        
        return fetchedResultController
    }
    
    public func cleanDatabase() {
        let entities = managedObjectModel.entities;
        
        for entity in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
            fetchRequest.entity = entity
            
            if #available(iOS 9.0, *) {
                let request = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                
                do {
                    try managedObjectContext.execute(request)
                } catch {
                    print(error.localizedDescription)
                }
            } else {
                fetchRequest.includesPropertyValues = false;
                
                do {
                    if let objs = try managedObjectContext.fetch(fetchRequest) as? [NSManagedObject] {
                        print("Eurocash - delete objects from: \(entity.name!) number of items: \(objs.count)")
                        for obj in objs {
                            managedObjectContext.delete(obj)
                        }
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        
        do {
            try managedObjectContext.save()
        } catch {
            
        }
    }
}
