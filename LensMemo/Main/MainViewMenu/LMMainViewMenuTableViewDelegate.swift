//
//  LMMainViewMenuTableViewDelegate.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-02.
//

import UIKit
import CoreData

class LMMainViewMenuTableViewDelegate: UITableViewDiffableDataSource<LMMainViewMenuTableViewDelegate.Section, AnyHashable>, UITableViewDelegate {
    
    weak var appContext: LMAppContext?
    
    static let __ADD_NOTEBOOK__ = AnyHashable(UUID())
    static let __ADD_STICKERS__ = AnyHashable(UUID())
    
    static let __JUST_SHOT__ = AnyHashable(UUID())
    static let __COVER__ = AnyHashable(UUID())
    static let __RECENTLY_VIEWED__ = AnyHashable(UUID())
    static let __SETTING__ = AnyHashable(UUID())
    
    init(tableView: UITableView, appContext: LMAppContext) throws {
        self.appContext = appContext
        tableView.register(UINib(nibName: String(describing: LMNotebookTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: LMNotebookTableViewCell.self))
        tableView.register(UINib(nibName: String(describing: LMButtonTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: LMButtonTableViewCell.self))
        tableView.register(LMTableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: String(describing: LMTableViewHeaderFooterView.self))
        super.init(tableView: tableView, cellProvider: { (tableView, indexPath, identifier) -> UITableViewCell? in
            switch Section(rawValue: indexPath.section) {
            case .header:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LMNotebookTableViewCell.self), for: indexPath) as? LMNotebookTableViewCell
                switch identifier {
                case LMMainViewMenuTableViewDelegate.__JUST_SHOT__:
                    cell?.configAsJustShot(appContext: appContext)
                case LMMainViewMenuTableViewDelegate.__COVER__:
                    cell?.configAsCover(appContext: appContext)
                case LMMainViewMenuTableViewDelegate.__RECENTLY_VIEWED__:
                    cell?.configAsRecentViewed(appContext: appContext)
                case LMMainViewMenuTableViewDelegate.__SETTING__:
                    cell?.configAsSetting(appContext: appContext)
                default:
                    break
                }
                return cell
            case .notebooks:
                
                if identifier == LMMainViewMenuTableViewDelegate.__ADD_NOTEBOOK__ {
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LMButtonTableViewCell.self), for: indexPath) as? LMButtonTableViewCell
                    cell?.configure(title: NSLocalizedString("Add Notebook", comment: "Add Notebook"), iconSystemName: "plus")
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LMNotebookTableViewCell.self), for: indexPath) as? LMNotebookTableViewCell
                    let count = appContext.noteBookService.fetchedResultsController.fetchedObjects?.count ?? 0
                    
                    if indexPath.row < count {
                        let noteBook = appContext.noteBookService.fetchedResultsController.object(at: IndexPath(row: indexPath.row, section: 0))
                        cell?.configure(data: noteBook, appContext: appContext)
                    }
                    
                    return cell
                }
                
            case .stickers:
                if identifier == LMMainViewMenuTableViewDelegate.__ADD_STICKERS__ {
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LMButtonTableViewCell.self), for: indexPath) as? LMButtonTableViewCell
                    cell?.configure(title: ~"Add Sticker", iconSystemName: "plus")
                    return cell
                } else {
                    let count = appContext.stickerService.fetchedResultsController.fetchedObjects?.count ?? 0
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LMNotebookTableViewCell.self), for: indexPath) as? LMNotebookTableViewCell
                    
                    if indexPath.row < count {
                        let sticker = appContext.stickerService.fetchedResultsController.object(at: IndexPath(row: indexPath.row, section: 0))
                        cell?.configure(sticker: sticker, appContext: appContext)
                    }
                    
                    return cell
                }
            case .none:
                return tableView.dequeueReusableCell(withIdentifier: String(describing: LMNotebookTableViewCell.self), for: indexPath)
            }
        })
        tableView.delegate = self
        tableView.dataSource = self
        tableView.dropDelegate = self
        appContext.storage.delegate.append(Weak(self))
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, AnyHashable>()
        snapshot.appendSections([.header, .notebooks, .stickers])
        snapshot.appendItems([
            LMMainViewMenuTableViewDelegate.__JUST_SHOT__,
            LMMainViewMenuTableViewDelegate.__COVER__,
            LMMainViewMenuTableViewDelegate.__RECENTLY_VIEWED__,
            LMMainViewMenuTableViewDelegate.__SETTING__], toSection: .header)
        let allNotebooksID = appContext.noteBookService.fetchedResultsController.fetchedObjects?.compactMap { $0.objectID } ?? []
        if !allNotebooksID.isEmpty {
            snapshot.appendItems(allNotebooksID, toSection: .notebooks)
        }
        snapshot.appendItems([LMMainViewMenuTableViewDelegate.__ADD_NOTEBOOK__], toSection: .notebooks)
        let allStickersBooksID = appContext.stickerService.fetchedResultsController.fetchedObjects?.compactMap { $0.objectID } ?? []
        if !allStickersBooksID.isEmpty {
            snapshot.appendItems(allStickersBooksID, toSection: .stickers)
        }
        snapshot.appendItems([LMMainViewMenuTableViewDelegate.__ADD_STICKERS__], toSection: .stickers)
        apply(snapshot)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            if indexPath.row >= tableView.numberOfRows(inSection: indexPath.section) - 1 {
                guard let alertViewController = appContext?.noteBookService.getAddNotebookAlert() else { return }
                appContext?.mainViewController.present(alertViewController, animated: true, completion: nil)
            } else {
                guard let targetNotebook = appContext?.noteBookService.fetchedResultsController.object(at: IndexPath(row: indexPath.row, section: 0)) else { return }
                appContext?.state.selectedNotebook = targetNotebook
                appContext?.navigateTo(notebook: targetNotebook)
            }
        case 2:
            if indexPath.row >= tableView.numberOfRows(inSection: indexPath.section) - 1 {
                guard let alertViewController = appContext?.stickerService.getAddStickerAlert() else { return }
                appContext?.mainViewController.present(alertViewController, animated: false, completion: nil)
            } else {
                guard let targetSticker = appContext?.stickerService.fetchedResultsController.object(at: IndexPath(row: indexPath.row, section: 0)) else { return }
                appContext?.state.selectedSticker = targetSticker
                appContext?.navigateTo(sticker: targetSticker)
            }
        default:
            return
        }
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            switch Section(rawValue: indexPath.section) {
            case .notebooks:
                guard let noteBook = appContext?.noteBookService.fetchedResultsController.object(at: IndexPath(row: indexPath.row, section: 0)) else { return }
                appContext?.noteBookService.deleteNotebook(notebook: noteBook)
            case .stickers:
                guard let sticker = appContext?.stickerService.fetchedResultsController.object(at: IndexPath(row: indexPath.row, section: 0)) else { return }
                appContext?.stickerService.deleteSticker(sticker: sticker)
            default:
                return
            }
        default:
            return
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        switch Section(rawValue: indexPath.section) {
        case .notebooks, .stickers: return true
        default: return false
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 1:
            return 32
        case 2:
            return 32
        default:
            return .leastNonzeroMagnitude
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: LMTableViewHeaderFooterView.self)) as? LMTableViewHeaderFooterView
        
        switch section {
        case 1:
            header?.title.text = NSLocalizedString("Notebooks", comment: "Notebooks")
        case 2:
            header?.title.text = NSLocalizedString("Stickers", comment: "Stickers")
        default:
            return UIView(frame: CGRect(x: 0, y: 0, width: CGFloat.leastNonzeroMagnitude, height: CGFloat.leastNonzeroMagnitude))
        }
        return header
    }
}

extension LMMainViewMenuTableViewDelegate: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {

        guard let indexPath = coordinator.destinationIndexPath else { return }
        
        var moveToNotebook: LMNotebook?
        var addingSticker: LMSticker?
        
        switch Section(rawValue: indexPath.section) {
        case .notebooks:
            if indexPath.row >= tableView.numberOfRows(inSection: indexPath.section) - 1 {
                for notebook in self.appContext?.noteBookService.fetchedResultsController.fetchedObjects ?? [] {
                    if notebook.name == "Dragged Items" {
                        moveToNotebook = notebook
                    }
                }
                if moveToNotebook == nil {
                    moveToNotebook = self.appContext?.noteBookService.addNotebook(name: "Dragged Items", color: "default")
                }
            } else {
                guard let targetNotebook = self.appContext?.noteBookService.fetchedResultsController.object(at: IndexPath(row: indexPath.row, section: 0)) else { return }
                moveToNotebook = targetNotebook
            }
        case .stickers:
            if indexPath.row >= tableView.numberOfRows(inSection: indexPath.section) - 1 {
                return
            } else {
                guard let targetSticker = self.appContext?.stickerService.fetchedResultsController.object(at: IndexPath(row: indexPath.row, section: 0)) else { return }
                addingSticker = targetSticker
            }
        default:
            return
        }
        
        
        
        if coordinator.session.localDragSession != nil {
            for item in coordinator.items {
                if let draggedNote = item.dragItem.localObject as? LMNote {
                    DispatchQueue.main.async {
                        if let notebook = moveToNotebook {
                            draggedNote.notebook = notebook
                            try? self.appContext?.storage.saveContext()
                        }
                        
                        if let sticker = addingSticker {
                            draggedNote.stickers = (draggedNote.stickers ?? NSSet()).adding(sticker) as NSSet
                            try? self.appContext?.storage.saveContext()
                        }
                        
                        tableView.reloadData()
                        #if targetEnvironment(macCatalyst)
                        let mainViewMenuNoteListViewController = self.appContext?.mainViewMenuNoteListViewController
                        #else
                        let mainViewMenuNoteListViewController = self.appContext?.mainViewMenuViewNavigationController.topViewController as? LMNoteListViewController
                        #endif
                        mainViewMenuNoteListViewController?.update()
                    }
                }
            }
        } else {
            if let notebook = moveToNotebook {
                appContext?.noteBookService.createNotesFromDraggedImage(coordinator: coordinator, in: notebook)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        guard let indexPath = destinationIndexPath else { return .init(operation: .forbidden) }
        
        switch Section(rawValue: destinationIndexPath?.section ?? 0) {
        case .notebooks:
            animateHoveringCell(tableView: tableView, indexPath: indexPath)
            return .init(operation: .move)
        case .stickers:
            if indexPath.row >= tableView.numberOfRows(inSection: indexPath.section) - 1 {
                return .init(operation: .forbidden)
            } else {
                if session.localDragSession != nil {
                    animateHoveringCell(tableView: tableView, indexPath: indexPath)
                    return .init(operation: .copy)
                } else {
                    return .init(operation: .forbidden)
                }
            }
        default:
            return .init(operation: .forbidden)
        }
    }
    
    func animateHoveringCell(tableView: UITableView, indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            let originalColor = cell.backgroundColor
            cell.backgroundColor = .tertiarySystemFill
            UIView.animate(withDuration: 0.3) {
                cell.backgroundColor = originalColor
            }
        }
    }
}

extension LMMainViewMenuTableViewDelegate: LMDataServiceDelegate {
    func contentChanged(snapshot: NSDiffableDataSourceSnapshotReference, type: String) {
        let identifiers = snapshot.itemIdentifiers.compactMap { $0 as? NSManagedObjectID}
        var newSnapshot = self.snapshot()
        switch type {
        case String(describing: LMNotebook.self):
            newSnapshot.deleteItems(newSnapshot.itemIdentifiers(inSection: .notebooks))
            newSnapshot.appendItems(identifiers, toSection: .notebooks)
            newSnapshot.appendItems([LMMainViewMenuTableViewDelegate.__ADD_NOTEBOOK__], toSection: .notebooks)
        case String(describing: LMSticker.self):
            newSnapshot.deleteItems(newSnapshot.itemIdentifiers(inSection: .stickers))
            newSnapshot.appendItems(identifiers, toSection: .stickers)
            newSnapshot.appendItems([LMMainViewMenuTableViewDelegate.__ADD_STICKERS__], toSection: .stickers)
        default:
            return
        }
        apply(newSnapshot)
    }
    
    enum Section: Int {
        case header = 0
        case notebooks = 1
        case stickers = 2
    }
}

protocol LMDataServiceDelegate: class {
    func contentChanged(snapshot: NSDiffableDataSourceSnapshotReference, type: String)
}
