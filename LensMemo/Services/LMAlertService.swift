//
//  LMAlertService.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-08-25.
//

import CoreData
import UIKit

class LMAlertService: ViewModel {
    var fetchedResultsController: NSFetchedResultsController<LMAlert>
    var viewContext: NSManagedObjectContext
    weak var appContext: LMAppContext!
    
    init(persistentService: LMPersistentStorageService) throws {
        fetchedResultsController = try LMAlertService.getFetchedResultsController(context: persistentService.viewContext)
        self.viewContext = persistentService.viewContext
        super.init()
        fetchedResultsController.delegate = self
    }
    
    private static func getFetchedResultsController(context: NSManagedObjectContext) throws -> NSFetchedResultsController<LMAlert> {
        let request: NSFetchRequest<LMAlert> = LMAlert.fetchRequest()
        request.fetchBatchSize = 20
        let sortDescriptor = NSSortDescriptor(key: "deadline", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: String(describing: LMNotebookDataService.self))
        do {
            try controller.performFetch()
        } catch (let error) {
            throw error
        }
        return controller
    }
}

extension LMAlertService: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        appContext.storage.delegate.forEach {
            ($0.value as? LMDataServiceDelegate)?.contentChanged(snapshot: snapshot, type: String(describing: LMAlert.self))
        }
    }
}
