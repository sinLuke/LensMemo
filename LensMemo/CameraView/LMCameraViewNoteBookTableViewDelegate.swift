//
//  LMCameraViewNotebookTableViewDelegate.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-05.
//

import UIKit
import CoreData

class LMCameraViewNotebookTableViewDelegate: UITableViewDiffableDataSource<AnyHashable, AnyHashable>, UITableViewDelegate {
    weak var appContext: LMAppContext?
    weak var tableView: UITableView?
    static let __ADD_NOTEBOOK__ = AnyHashable(UUID())
    
    init(tableView: UITableView, appContext: LMAppContext) throws {
        self.appContext = appContext
        self.tableView = tableView
        tableView.register(UINib(nibName: String(describing: LMCameraNotebookTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: LMCameraNotebookTableViewCell.self))
        super.init(tableView: tableView) { (tableView, indexPath, identifier) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LMCameraNotebookTableViewCell.self), for: indexPath) as? LMCameraNotebookTableViewCell
            if identifier == LMCameraViewNotebookTableViewDelegate.__ADD_NOTEBOOK__ {
                cell?.configure(data: nil, appContext: appContext)
            } else {
                let noteBook = appContext.noteBookService.fetchedResultsController.object(at: indexPath)
                cell?.configure(data: noteBook, appContext: appContext)
            }
            return cell
        }
        appContext.storage.delegate.append(Weak(self))
        var snapshot = NSDiffableDataSourceSnapshot<AnyHashable, AnyHashable>()
        snapshot.appendSections([""])
        
        let allNotebooksID = appContext.noteBookService.fetchedResultsController.fetchedObjects?.compactMap { $0.objectID } ?? []
        applySnapshotFrom(allNotebooksID: allNotebooksID)
    }

    func applySnapshotFrom(allNotebooksID: [NSManagedObjectID]) {
        var newSnapshot = NSDiffableDataSourceSnapshot<AnyHashable, AnyHashable>()
        newSnapshot.appendSections([""])
        if !allNotebooksID.isEmpty {
            newSnapshot.appendItems(allNotebooksID)
        } else {
            newSnapshot.appendItems([LMCameraViewNotebookTableViewDelegate.__ADD_NOTEBOOK__])
        }
        apply(newSnapshot, animatingDifferences: true, completion: {
            self.updateTableViewContentInset()
        })
    }
    
    func updateTableViewContentInset() {
        guard let tableView = self.tableView else { return }
        let viewHeight: CGFloat = tableView.frame.size.height
        let tableViewContentHeight: CGFloat = tableView.contentSize.height
        let marginHeight: CGFloat = max(16, (viewHeight - tableViewContentHeight) / 2.0)
        UIView.animate(withDuration: 0.3) {
            tableView.contentInset = UIEdgeInsets(top: marginHeight, left: 0, bottom:  -marginHeight, right: 0)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if snapshot().itemIdentifiers.first != LMCameraViewNotebookTableViewDelegate.__ADD_NOTEBOOK__ {
            guard let targetNotebook = appContext?.noteBookService.fetchedResultsController.object(at: IndexPath(row: indexPath.row, section: 0)) else { return }
            appContext?.state.selectedNotebook = targetNotebook
            appContext?.navigateTo(notebook: targetNotebook)
        }
        tableView.reloadData()
    }
}

extension LMCameraViewNotebookTableViewDelegate: LMDataServiceDelegate {
    func contentChanged(snapshot: NSDiffableDataSourceSnapshotReference, type: String) {
        guard type == String(describing: LMNotebook.self) else { return }
        applySnapshotFrom(allNotebooksID: snapshot.itemIdentifiers as? [NSManagedObjectID] ?? [])
    }
}
