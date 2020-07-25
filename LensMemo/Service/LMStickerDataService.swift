//
//  LMStickerDataService.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-02.
//

import CoreData
import UIKit

class LMStickerDataService: ViewModel {
    var fetchedResultsController: NSFetchedResultsController<LMSticker>
    weak var appContext: LMAppContext!
    var viewContext: NSManagedObjectContext
    init(persistentService: LMPersistentStorageService) throws {
        fetchedResultsController = try LMStickerDataService.getFetchedResultsController(context: persistentService.viewContext)
        self.viewContext = persistentService.viewContext
        super.init()
        fetchedResultsController.delegate = self
    }
    private static func getFetchedResultsController(context: NSManagedObjectContext) throws -> NSFetchedResultsController<LMSticker> {
        let request: NSFetchRequest<LMSticker> = LMSticker.fetchRequest()
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

extension LMStickerDataService: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        appContext.storage.delegate.forEach {
            ($0.value as? LMDataServiceDelegate)?.contentChanged(snapshot: snapshot, type: String(describing: LMSticker.self))
        }
    }
}
