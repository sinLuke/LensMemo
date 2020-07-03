//
//  LMPersistentStorageService.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-01.
//

import CoreData

class LMPersistentStorageService: NSObject {
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LensMemo_iOS")
        container.loadPersistentStores { (description, error) in
            if let error = error {
                fatalError()
            }
        }
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges { try? context.save() }
    }
}
