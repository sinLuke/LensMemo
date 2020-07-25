//
//  LMMainViewMenuTableViewDelegate.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-02.
//

import UIKit
import CoreData

class LMMainViewMenuTableViewDelegate: UITableViewDiffableDataSource<LMMainViewMenuTableViewDelegate.Section, AnyHashable>, UITableViewDelegate {
    
    var appContext: LMAppContext
    
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
                        cell?.configAsJustShot()
                    case LMMainViewMenuTableViewDelegate.__COVER__:
                        cell?.configAsCover()
                    case LMMainViewMenuTableViewDelegate.__RECENTLY_VIEWED__:
                        cell?.configAsRecentViewed()
                    case LMMainViewMenuTableViewDelegate.__SETTING__:
                        cell?.configAsSetting()
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
                    let noteBook = appContext.noteBookService.fetchedResultsController.object(at: IndexPath(row: indexPath.row, section: 0))
                    cell?.configure(data: noteBook)
                    
                    return cell
                }
                
            case .stickers:
                if identifier == LMMainViewMenuTableViewDelegate.__ADD_STICKERS__ {
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LMButtonTableViewCell.self), for: indexPath) as? LMButtonTableViewCell
                    cell?.configure(title: NSLocalizedString("Add Sticker", comment: "Add Sticker"), iconSystemName: "plus")
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LMNotebookTableViewCell.self), for: indexPath) as? LMNotebookTableViewCell
//                    if let id = identifier as? NSManagedObjectID, let sticker = appContext.storage.viewContext.object(with: id) as? LMSticker {
//                        cell?.configure(data: sticker)
//                    }
                    return cell
                }
            case .none:
                return tableView.dequeueReusableCell(withIdentifier: String(describing: LMNotebookTableViewCell.self), for: indexPath)
            }
        })
        tableView.delegate = self
        tableView.dataSource = self
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
                let alertViewController = appContext.noteBookService.getAddNotebookAlert()
                appContext.mainViewController.present(alertViewController, animated: true, completion: nil)
            } else {
                let targetNotebook = appContext.noteBookService.fetchedResultsController.object(at: IndexPath(row: indexPath.row, section: 0))
                appContext.state.selectedNotebook = targetNotebook
                appContext.navigateTo(notebook: targetNotebook)
            }
        case 2:
            if indexPath.row >= tableView.numberOfRows(inSection: indexPath.section) - 1 {
                
            } else {
                appContext.state.selectedSticker = appContext.stickerService.fetchedResultsController.object(at: IndexPath(row: indexPath.row, section: 0))
            }
        default:
            return
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
