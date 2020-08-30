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
    
    func deleteSticker(sticker: LMSticker) {
        viewContext.delete(sticker)
        if appContext.state.selectedSticker == sticker {
            appContext.state.selectedSticker = nil
        }
        if appContext.state.applyingSticker == sticker {
            appContext.state.applyingSticker = nil
        }
        try? viewContext.save()
    }
    
    func getAddStickerAlert() -> LMAlertViewViewController {
        var stcikerName: NSString = ""
        let alertViewController: LMAlertViewViewController?
        weak var weakAlertViewController: LMAlertViewViewController?
        let alertData = LMAlertViewViewController.Data(
            allowDismiss: false,
            icon: UIImage(systemName: "square.and.pencil"),
            color: .label,
            title: "Add a sticker",
            messages: [],
            textFields: [
                LMAlertViewViewController.TextField(title: ~"Input Note Book Name Here", defaultValue: "New Notebook", onEditingEnd: { (string) in
                    if !string.isEmpty {
                        stcikerName = string as NSString
                        weakAlertViewController?.inputsValid["Sticker name or icon already exist"] = true
                        self.appContext.stickerService.fetchedResultsController.fetchedObjects?.forEach({
                            if string.first == $0.name?.first {
                                weakAlertViewController?.inputsValid["sticker name or icon already exist"] = false
                            }
                        })
                    }
                    weakAlertViewController?.inputsValid["Sticker name can not be empty"] = !string.isEmpty
                    
                })
            ], buttons: [
                LMAlertViewViewController.Button(title: NSLocalizedString("Cancel", comment: "Cancel"), validateInput: false, onTap: {
                    weakAlertViewController?.dismiss(animated: false, completion: nil)
                }),
                LMAlertViewViewController.Button(title: NSLocalizedString("Create", comment: "Create"), validateInput: true, onTap: {
                    if !"\(stcikerName)".isEmpty {
                        self.addSticker(name: stcikerName)
                        weakAlertViewController?.dismiss(animated: false, completion: nil)
                    } else {
                        weakAlertViewController?.inputsValid["Sticker name can not be empty"] = false
                    }
                })
        ])
        alertViewController = LMAlertViewViewController.getInstance(data: alertData)
        weakAlertViewController = alertViewController
        return alertViewController!
    }
    
    func addSticker(name: NSString) {
        
        for sticker in fetchedResultsController.fetchedObjects ?? [] {
            if sticker.name?.first == (name as String).first {
                return
            }
        }
        
        guard let sticker = NSEntityDescription.insertNewObject(forEntityName: "LMSticker", into: viewContext) as? LMSticker else { return }
        
        sticker.created = Date()
        sticker.id = UUID()
        sticker.name = name as String
        
        appContext.state.selectedSticker = sticker
        try! viewContext.save()
    }
}

extension LMStickerDataService: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        appContext.storage.delegate.forEach {
            ($0.value as? LMDataServiceDelegate)?.contentChanged(snapshot: snapshot, type: String(describing: LMSticker.self))
        }
    }
}
