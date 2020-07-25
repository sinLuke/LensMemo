//
//  LMPersistentStorageService.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-01.
//

import CoreData
import CloudKit

class LMPersistentStorageService {
    var delegate: [Weak<NSObject>] = []
    var persistentContainer: NSPersistentCloudKitContainer
    
    private lazy var historyQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    static func getInstance(callBack: @escaping (Result<LMPersistentStorageService, Error>) -> () ) {
        let service = LMPersistentStorageService(persistentContainer: NSPersistentCloudKitContainer(name: "LensMemo_iOS"))
        
        // get the store description
        guard let description = service.persistentContainer.persistentStoreDescriptions.first else {
            fatalError("Could not retrieve a persistent store description.")
        }
        
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        service.persistentContainer.loadPersistentStores { (description, error) in
            if let error = error {
                callBack(.failure(error))
            } else {
                callBack(.success(service))
            }
        }
        
        service.persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        service.persistentContainer.viewContext.transactionAuthor = "app"
        
        service.persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        do {
            try service.persistentContainer.viewContext.setQueryGenerationFrom(.current)
        } catch {
            callBack(.failure(error))
        }
    }
    
    private init(persistentContainer: NSPersistentCloudKitContainer) {
        self.persistentContainer = persistentContainer
    }
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func saveContext() throws {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                throw nserror
            }
        }
    }
}
