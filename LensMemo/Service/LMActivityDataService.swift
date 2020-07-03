//
//  LMActivityDataService.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-02.
//

import CoreData
import UIKit

class LMActivityDataService: ViewModel {
    var fetchedResultsController: NSFetchedResultsController<LMActivity>
    init(persistentService: LMPersistentStorageService) throws {
        fetchedResultsController = try LMActivityDataService.getFetchedResultsController(context: persistentService.viewContext)
        super.init()
        fetchedResultsController.delegate = self
    }
    private static func getFetchedResultsController(context: NSManagedObjectContext) throws -> NSFetchedResultsController<LMActivity> {
        let request: NSFetchRequest<LMActivity> = LMActivity.fetchRequest()
        request.fetchBatchSize = 20
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: String(describing: LMActivityDataService.self))
        do {
            try controller.performFetch()
        } catch (let error) {
            throw error
        }
        return controller
    }
}

extension LMActivityDataService: NSFetchedResultsControllerDelegate {
    
}
