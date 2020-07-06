//
//  LMNoteDataService.swift
//  LensMemo-iOS
//
//  Created by Luke Yin on 2020-07-01.
//

import CoreData
import UIKit

class LMNoteDataService: ViewModel {
    var viewContext: NSManagedObjectContext
    var appContext: LMAppContext!
    var sortBy: SortBy = .created
    init(persistentService: LMPersistentStorageService) throws {
        self.viewContext = persistentService.viewContext
        super.init()
    }
    
    var cacheFetchedResultsController: [UUID: NSFetchedResultsController<LMNote>] = [:]
    
    func fetchedResultsController(noteBook: LMNotebook?, thatsOnCover: Bool) -> NSFetchedResultsController<LMNote>? {
        if let identifier = noteBook?.id, cacheFetchedResultsController.keys.contains(identifier) {
            let controller = cacheFetchedResultsController[identifier]
            return controller
        }
        let request: NSFetchRequest<LMNote> = LMNote.fetchRequest()
        request.fetchBatchSize = 20
        let sortDescriptor = NSSortDescriptor(key: "created", ascending: true)
        if let noteBook = noteBook {
            request.predicate = NSPredicate(format: "notebook == %@", noteBook)
        } else if thatsOnCover {
            request.predicate = NSPredicate(format: "onCover = YES")
        }
        
        request.sortDescriptors = [sortDescriptor]
        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: viewContext,
            sectionNameKeyPath: nil,
            cacheName: noteBook?.id?.uuidString)
        do {
            try controller.performFetch()
        } catch (let _) {
            return nil
        }
        controller.delegate = self
        if let identifier = noteBook?.id {
            cacheFetchedResultsController[identifier] = controller
        }
        return controller
    }
    
    func addNote(name: NSString, message: NSString, image: UIImage?, stickers: [LMSticker]) {
        guard let image = image, let newNote = NSEntityDescription.insertNewObject(forEntityName: "LMNote", into: viewContext) as? LMNote else { return }
        
        if appContext.state.selectedNotebook == nil {
            appContext.noteBookService.addNotebook(name: "New Notebook", color: "default")
        }

        newNote.created = Date()
        newNote.id = UUID()
        newNote.lastViewed = Date()
        newNote.name = name as String
        newNote.message = message as String
        newNote.notebook = appContext.state.selectedNotebook
        newNote.stickers = NSSet(array: stickers)
        try! viewContext.save()
    }
}

extension LMNoteDataService: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        appContext.storage.delegate.forEach {
            ($0.value as? LMDataServiceDelegate)?.contentChanged(snapshot: snapshot, type: String(describing: LMNote.self))
        }
    }
}

extension LMNoteDataService {
    enum SortBy: String {
        case created
        case lastViewd
    }
    
    enum SectionBy: String {
        case sticker
        case lastViewd
    }
}
