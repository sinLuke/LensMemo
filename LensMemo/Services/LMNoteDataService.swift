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
    weak var appContext: LMAppContext!
    var sortBy: SortBy = .created
    init(persistentService: LMPersistentStorageService) throws {
        self.viewContext = persistentService.viewContext
        super.init()
    }
    
    var cacheFetchedResultsController: [UUID: NSFetchedResultsController<LMNote>] = [:]
    
    func fetchedResultsController(noteBook: LMNotebook?, sticker: LMSticker?, thatsOnCover: Bool) -> NSFetchedResultsController<LMNote>? {
        if let identifier = noteBook?.id, cacheFetchedResultsController.keys.contains(identifier) {
            let controller = cacheFetchedResultsController[identifier]
            return controller
        }
        let request: NSFetchRequest<LMNote> = LMNote.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "created", ascending: true)
        if let noteBook = noteBook {
            request.predicate = NSPredicate(format: "notebook == %@", noteBook)
        } else if thatsOnCover {
            request.predicate = NSPredicate(format: "onCover = YES")
        } else if let sticker = sticker {
            request.predicate = NSPredicate(format: "%@ IN stickers", sticker)
        }
        
        request.sortDescriptors = [sortDescriptor]
        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: viewContext,
            sectionNameKeyPath: nil,
            cacheName: noteBook?.id?.uuidString ?? sticker?.id?.uuidString)
        do {
            try controller.performFetch()
        } catch {
            return nil
        }
        controller.delegate = self
        if let identifier = noteBook?.id ?? sticker?.id {
            cacheFetchedResultsController[identifier] = controller
        }
        return controller
    }
    
    func deleteNote(note: LMNote) {
        viewContext.delete(note)
        try? viewContext.save()
    }
    
    func addNote(name: NSString, to notebook: LMNotebook? = nil, message: NSString, image: UIImage?, stickers: [LMSticker], result: @escaping (Result<LMNote, Error>) -> ()) {
        guard let image = image, let newNote = NSEntityDescription.insertNewObject(forEntityName: "LMNote", into: viewContext) as? LMNote else {
            result(.failure(LMError.errorWhenSaveImage))
            return
        }
        
        if appContext.state.selectedNotebook == nil, notebook == nil {
            _ = appContext.noteBookService.addNotebook(name: "New Notebook", color: "default")
        }
        
        let newNoteID = UUID()
        newNote.created = Date()
        newNote.id = newNoteID
        newNote.lastViewed = Date()
        newNote.name = name as String
        newNote.message = message as String
        newNote.notebook = notebook ?? appContext.state.selectedNotebook
        newNote.stickers = NSSet(array: stickers)
        newNote.isDocument = false
        newNote.compactColor = image.compactColor ?? 0
        newNote.imageHeight = Int64(image.size.height)
        newNote.imageWidth = Int64(image.size.width)
        
        appContext.imageService.saveImage(image: image, note: newNote) { (imageResult) in
            imageResult.see(ifSuccess: { _ in
                do {
                    try self.viewContext.save()
                    result(.success(newNote))
                } catch (let error) {
                    result(.failure(error))
                }
            }) { (error) in
                result(.failure(error))
            }
        }
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
