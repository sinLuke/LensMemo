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
    var viewContext: NSManagedObjectContext
    weak var appContext: LMAppContext!
    
    init(persistentService: LMPersistentStorageService) throws {
        fetchedResultsController = try LMNotebookDataService.getFetchedResultsController(context: persistentService.viewContext)
        self.viewContext = persistentService.viewContext
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
    
    func getAddNotebookAlert() -> LMAlertViewViewController {
        var noteBookName: NSString = ""
        var noteBookColor: NSString = ""
        let alertViewController: LMAlertViewViewController?
        weak var weakAlertViewController: LMAlertViewViewController?
        let alertData = LMAlertViewViewController.Data(
            allowDismiss: false,
            icon: UIImage(systemName: "square.and.pencil"),
            color: .label,
            title: "Add a note book",
            messages: [],
            colorPicker: {(string) in
                noteBookColor = string as NSString
            },
            textFields: [LMAlertViewViewController.TextField(title: NSLocalizedString("Input Note Book Name Here", comment: "Input Note Book Name Here"), defaultValue: "New Notebook", onEditingEnd: { (string) in
                if !string.isEmpty {
                    noteBookName = string as NSString
                }
                weakAlertViewController?.inputsValid["Notebook name cannot be empty"] = !string.isEmpty
            })],
            buttons: [
                LMAlertViewViewController.Button(title: NSLocalizedString("Create", comment: "Create"), validateInput: true, onTap: {
                if !"\(noteBookName)".isEmpty {
                    _ = self.addNotebook(name: noteBookName, color: noteBookColor)
                    weakAlertViewController?.dismiss(animated: false, completion: nil)
                } else {
                    weakAlertViewController?.inputsValid["Notebook name cannot be empty"] = false
                }
            }),
                LMAlertViewViewController.Button(title: NSLocalizedString("Cancel", comment: "Cancel"), validateInput: false, onTap: {
                    weakAlertViewController?.dismiss(animated: true, completion: nil)
                })
            ]
        )
        alertViewController = LMAlertViewViewController.getInstance(data: alertData)
        weakAlertViewController = alertViewController
        return alertViewController!
    }
    
    func deleteNotebook(notebook: LMNotebook) {
        viewContext.delete(notebook)
        if appContext.state.selectedNotebook == notebook {
            appContext.state.selectedNotebook = nil
        }
        try? viewContext.save()
    }
    
    func addNotebook(name: NSString, color: NSString) -> LMNotebook? {
        guard let newNotebook = NSEntityDescription.insertNewObject(forEntityName: "LMNotebook", into: viewContext) as? LMNotebook else { return nil }

        newNotebook.color = color as String
        newNotebook.created = Date()
        newNotebook.id = UUID()
        newNotebook.isHidden = false
        newNotebook.modified = Date()
        newNotebook.name = name as String
        appContext.state.selectedNotebook = newNotebook
        try! viewContext.save()
        return newNotebook
    }
    
    func createNotesFromDraggedImage(coordinator: UITableViewDropCoordinator, in notebook: LMNotebook) {
        let session = LMNotesDragDropSession(dragItem: coordinator.items.compactMap { $0.dragItem }, notebook: notebook, appContext: appContext)
        session.createNotes()
    }
    
    func createNotesFromDraggedImage(coordinator: UICollectionViewDropCoordinator, in notebook: LMNotebook) {
        let session = LMNotesDragDropSession(dragItem: coordinator.items.compactMap { $0.dragItem }, notebook: notebook, appContext: appContext)
        session.createNotes()
    }
}

extension LMNotebookDataService: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        appContext.storage.delegate.forEach {
            ($0.value as? LMDataServiceDelegate)?.contentChanged(snapshot: snapshot, type: String(describing: LMNotebook.self))
        }
    }
}

extension LMNotebookDataService {
    enum NotebookColor: String {
        case black
        case red
        case orange
        case yellow
        case green
        case teal
        case blue
        case purple
        
        func getColor() -> UIColor {
            switch self {
            case .black:
                return .label
            case .red:
                return .systemRed
            case .orange:
                return .systemOrange
            case .yellow:
                return .systemYellow
            case .green:
                return .systemGreen
            case .teal:
                return .systemTeal
            case .blue:
                return .systemBlue
            case .purple:
                return .systemPurple
            }
        }
    }
}
