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
    var appContext: LMAppContext!
    
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
        var alertViewController: LMAlertViewViewController?
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
            })],
            primaryButton: LMAlertViewViewController.Button(title: NSLocalizedString("Create", comment: "Create"), onTap: {
                self.addNotebook(name: noteBookName, color: noteBookColor)
                alertViewController?.dismiss(animated: true, completion: nil)
            }),
            secondaryButton: LMAlertViewViewController.Button(title: NSLocalizedString("Cancel", comment: "Cancel"), onTap: {
                alertViewController?.dismiss(animated: true, completion: nil)
            })
        )
        alertViewController = LMAlertViewViewController.getInstance(data: alertData)
        return alertViewController!
    }
    
    func addNotebook(name: NSString, color: NSString) {
        guard let newNotebook = NSEntityDescription.insertNewObject(forEntityName: "LMNotebook", into: viewContext) as? LMNotebook else { return }

        newNotebook.color = color as String
        newNotebook.created = Date()
        newNotebook.id = UUID()
        newNotebook.isHidden = false
        newNotebook.modified = Date()
        newNotebook.name = name as String
        appContext.state.selectedNotebook = newNotebook
        try! viewContext.save()
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
