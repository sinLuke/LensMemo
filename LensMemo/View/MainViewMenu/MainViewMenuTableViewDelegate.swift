//
//  MainViewMenuTableViewDelegate.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-02.
//

import UIKit
import CoreData

class MainViewMenuTableViewDelegate: UITableViewDiffableDataSource<MainViewMenuTableViewDelegate.Section, AnyHashable>, UITableViewDelegate {
    
    init(tableView: UITableView, appContext: LMAppContext) throws {
        super.init(tableView: tableView, cellProvider: { (tableView, indexPath, identifier) -> UITableViewCell? in
            switch Section(rawValue: indexPath.section) {
            case .header:
                let cell = tableView.dequeueReusableCell(withIdentifier: "id", for: indexPath)
                let noteBook = appContext.noteBookService.fetchedResultsController.object(at: IndexPath(row: indexPath.row, section: 0))
                cell.textLabel?.text = "\(noteBook.created ?? Date())"
                return cell
            case .notebooks:
                let cell = tableView.dequeueReusableCell(withIdentifier: "id", for: indexPath)
                let noteBook = appContext.noteBookService.fetchedResultsController.object(at: IndexPath(row: indexPath.row, section: 0))
                cell.textLabel?.text = noteBook.name
                return cell
            case .stickers:
                let cell = tableView.dequeueReusableCell(withIdentifier: "id", for: indexPath)
                let sticker = appContext.stickerService.fetchedResultsController.object(at: IndexPath(row: indexPath.row, section: 0))
                cell.textLabel?.text = "\(sticker.created ?? Date())"
                return cell
            case .none:
                return tableView.dequeueReusableCell(withIdentifier: "id", for: indexPath)
            }
        })
        appContext.noteBookService.delegate = self
        appContext.stickerService.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "id")
        var snapshot = NSDiffableDataSourceSnapshot<Section, AnyHashable>()
        snapshot.appendSections([.header, .notebooks, .stickers])
        snapshot.appendItems([], toSection: .header)
        snapshot.appendItems(appContext.noteBookService.fetchedResultsController.fetchedObjects?.compactMap { $0.objectID } ?? [], toSection: .notebooks)
        snapshot.appendItems(appContext.stickerService.fetchedResultsController.fetchedObjects?.compactMap { $0.objectID } ?? [], toSection: .stickers)
        
        apply(snapshot)
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return [
            nil,
            "Notebooks",
            "Sticker"
        ][section]
    }
}

extension MainViewMenuTableViewDelegate: LMDataServiceDelegate {
    func contentChanged(snapshot: NSDiffableDataSourceSnapshotReference, type: String) {
        let identifiers = snapshot.itemIdentifiers.compactMap { $0 as? NSManagedObjectID}
        var snapshot = self.snapshot()
        switch type {
        case String(describing: LMNotebook.self):
            snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .notebooks))
            snapshot.appendItems(identifiers, toSection: .notebooks)
        case String(describing: LMSticker.self):
            snapshot.deleteItems(snapshot.itemIdentifiers(inSection: .stickers))
            snapshot.appendItems(identifiers, toSection: .stickers)
        default:
            return
        }
        apply(snapshot)
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
