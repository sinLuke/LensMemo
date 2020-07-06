//
//  LMPersistentStorageService.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-01.
//

import CoreData

class LMPersistentStorageService {
    var delegate: [Weak<NSObject>] = []
    var persistentContainer: NSPersistentContainer
    
    static func getInstance(callBack: @escaping (Result<LMPersistentStorageService, Error>) -> () ) {
        let service = LMPersistentStorageService(persistentContainer: NSPersistentContainer(name: "LensMemo_iOS"))
        service.persistentContainer.loadPersistentStores { (description, error) in
            if let error = error {
                callBack(.failure(error))
            } else {
                callBack(.success(service))
            }
        }
    }
    
    private init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
    }
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges { try? context.save() }
    }
}
