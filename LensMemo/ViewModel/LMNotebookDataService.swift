//
//  LMNotebookDataService.swift
//  LensMemo-iOS
//
//  Created by Luke Yin on 2020-07-01.
//

import CoreData
import UIKit

class LMNotebookDataService: ViewModel {
    var fetchedResultsController: NSFetchedResultsController<LMNotebook>
    weak var delegate: LMDataServiceDelegate?
    init(persistentService: LMPersistentStorageService) throws {
        fetchedResultsController = try LMNotebookDataService.getFetchedResultsController(context: persistentService.viewContext)
        super.init()
        fetchedResultsController.delegate = self
    }
    private static func getFetchedResultsController(context: NSManagedObjectContext) throws -> NSFetchedResultsController<LMNotebook> {
        let request: NSFetchRequest<LMNotebook> = LMNotebook.fetchRequest()
        request.fetchBatchSize = 20
        let sortDescriptor = NSSortDescriptor(key: "created", ascending: true)
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

extension LMNotebookDataService: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        delegate?.contentChanged(snapshot: snapshot, type: String(describing: LMNotebook.self))
    }
}
