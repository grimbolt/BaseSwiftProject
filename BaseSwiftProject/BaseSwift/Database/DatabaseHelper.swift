//
//  AppDelegate+CoreData.swift
//  BaseSwiftProject
//
//  Created by Grimbolt on 07.01.2017.
//
//

import Foundation
import CoreData

class DatabaseHelper: NSObject {
    
    static let sharedInstance = DatabaseHelper()

    private static let lock = NSLock()

    private static let infoBlock :Any? = {
        PRINT("▿ App location:\n\(DatabaseHelper.applicationDocumentsDirectory)\n\n")
        return nil
    }()

    // MARK: - Core Data stack
    
    static let applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.test.Core_Data" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1] as NSURL
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: DATABASE_NAME, withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = DatabaseHelper.applicationDocumentsDirectory.appendingPathComponent(DATABASE_FILE_NAME)
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
            LOG("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    private func saveContext (context: NSManagedObjectContext) {
        DatabaseHelper.lock.lock()
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                LOG("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
        DatabaseHelper.lock.unlock()
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
    
    lazy var backgroundContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.persistentStoreCoordinator = coordinator
        return backgroundContext
    }()
    
    func saveContext () {
        self.saveContext( context: self.backgroundContext )
    }
    
    func appWillTerminate(_ notification: Notification) {
        saveContext()
    }
    
    func contextDidSaveContext(notification: NSNotification) {
        let sender = notification.object as! NSManagedObjectContext
        if sender === self.managedObjectContext {
            LOG("******** Saved main Context in this thread")
            self.backgroundContext.perform {
                self.backgroundContext.mergeChanges(fromContextDidSave: notification as Notification)
            }
        } else if sender === self.backgroundContext {
            LOG("******** Saved background Context in this thread")
            self.managedObjectContext.perform {
                self.managedObjectContext.mergeChanges(fromContextDidSave: notification as Notification)
            }
        } else {
            LOG("******** Saved Context in other thread")
            self.backgroundContext.perform {
                self.backgroundContext.mergeChanges(fromContextDidSave: notification as Notification)
            }
            self.managedObjectContext.perform {
                self.managedObjectContext.mergeChanges(fromContextDidSave: notification as Notification)
            }
        }
    }

    // MARK: - Core Data methods

    func fetch(entityName: String, format: String = "") -> [NSManagedObject] {
        return fetch(entityName: entityName, format: format, withLock: true)
    }

    private func fetch(entityName: String, format: String = "", withLock: Bool) -> [NSManagedObject] {
        if withLock { DatabaseHelper.lock.lock() }
        
        var objects: [NSManagedObject] = [NSManagedObject]()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        if format != "" {
            fetchRequest.predicate = NSPredicate(format: format)
        }

        do {
            let results = try backgroundContext.fetch(fetchRequest)
            objects += results as! [NSManagedObject]
        } catch let error as NSError {
            PRINT("Could not fetch \(error), \(error.userInfo)")
        }
        
        if withLock { DatabaseHelper.lock.unlock() }
        return objects;
    }
    
    func fetchCount(entityName: String, format: String = "") -> Int {
        DatabaseHelper.lock.lock()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        if format != "" {
            fetchRequest.predicate = NSPredicate(format: format)
        }
        
        do {
            let results = try backgroundContext.count(for: fetchRequest)
            return results;
        } catch let error as NSError {
            PRINT("Could not fetch \(error), \(error.userInfo)")
        }
        
        DatabaseHelper.lock.unlock()
        return -1
    }

    func delete(entityName: String, format: String = "") {
        DatabaseHelper.lock.lock()
        let objects: [NSManagedObject] = fetch(entityName: entityName, format: format, withLock: false)
        for object in objects {
            backgroundContext.delete(object)
        }
        DatabaseHelper.lock.unlock()
    }

    func createFetchedResultController(_ entityName: String, sortDescriptor: [NSSortDescriptor]?, predicate: NSPredicate?) -> NSFetchedResultsController<NSFetchRequestResult>? {
        DatabaseHelper.lock.lock()
        
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
        
        DatabaseHelper.lock.unlock()
        return fetchedResultController
    }
}
