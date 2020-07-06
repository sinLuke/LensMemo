//
//  MainViewMenuNoteListTableViewDelegate.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-04.
//

import UIKit
import CoreData

class MainViewMenuNoteListTableViewDelegate: UITableViewDiffableDataSource<AnyHashable, NSManagedObjectID>, UITableViewDelegate {

    var appContext: LMAppContext
    var notebook: LMNotebook?
    weak var tableView: UITableView?
    
    init(tableView: UITableView, appContext: LMAppContext, notebook: LMNotebook?, thatsOnCover: Bool) throws {
        self.appContext = appContext
        self.notebook = notebook
        self.tableView = tableView

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "id")
        super.init(tableView: tableView) { (tableView, indexPath, identifier) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: "id", for: indexPath)
            let note = appContext.noteService.fetchedResultsController(noteBook: notebook, thatsOnCover: thatsOnCover)?.object(at: indexPath)
            cell.textLabel?.text = "\(note?.created ?? Date())"
            return cell
        }

        appContext.storage.delegate.append(Weak(self))
        let allNotesID = appContext.noteService.fetchedResultsController(noteBook: notebook, thatsOnCover: thatsOnCover)?.fetchedObjects?.compactMap { $0.objectID } ?? []
        var newSnapshot = snapshot()
        if let existingSection = newSnapshot.sectionIdentifiers.first {
            newSnapshot.deleteSections([existingSection])
        }
        newSnapshot.appendSections([""])
        newSnapshot.appendItems(allNotesID)
        apply(newSnapshot)
    }
}

extension MainViewMenuNoteListTableViewDelegate: LMDataServiceDelegate {
    func contentChanged(snapshot: NSDiffableDataSourceSnapshotReference, type: String) {
        guard type == String(describing: LMNote.self) else { return }

        apply(snapshot as NSDiffableDataSourceSnapshot<AnyHashable, NSManagedObjectID>)
    }
}
