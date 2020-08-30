//
//  LMCameraViewStickerTableViewDelegate.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-05.
//

import UIKit
import CoreData

class LMCameraViewStickerTableViewDelegate: UITableViewDiffableDataSource<AnyHashable, AnyHashable>, UITableViewDelegate {
    weak var appContext: LMAppContext?
    weak var tableView: UITableView?
    static let __NO_STICKER__ = AnyHashable(UUID())
    
    init(tableView: UITableView, appContext: LMAppContext) throws {
        self.appContext = appContext
        self.tableView = tableView
        tableView.register(UINib(nibName: String(describing: LMCameraStickerTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: LMCameraStickerTableViewCell.self))
        super.init(tableView: tableView) { (tableView, indexPath, identifier) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LMCameraStickerTableViewCell.self), for: indexPath) as? LMCameraStickerTableViewCell
            if identifier == LMCameraViewStickerTableViewDelegate.__NO_STICKER__ {
                cell?.configure(data: nil, appContext: appContext)
            } else if let id = identifier as? NSManagedObjectID, let sticker = appContext.stickerService.viewContext.object(with: id) as? LMSticker {
                cell?.configure(data: sticker, appContext: appContext)
            }
            return cell
        }
        appContext.storage.delegate.append(Weak(self))
        var snapshot = NSDiffableDataSourceSnapshot<AnyHashable, AnyHashable>()
        snapshot.appendSections([""])
        
        let allStickerID = appContext.stickerService.fetchedResultsController.fetchedObjects?.compactMap { $0.objectID } ?? []
        applySnapshotFrom(allStickerID: allStickerID)
    }
    
    func applySnapshotFrom(allStickerID: [NSManagedObjectID]) {
        var newSnapshot = NSDiffableDataSourceSnapshot<AnyHashable, AnyHashable>()
        newSnapshot.appendSections([""])
        if !allStickerID.isEmpty {
            newSnapshot.appendItems([LMCameraViewStickerTableViewDelegate.__NO_STICKER__])
            newSnapshot.appendItems(allStickerID)
        } else {
            newSnapshot.appendItems([LMCameraViewStickerTableViewDelegate.__NO_STICKER__])
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
        if indexPath.row == 0 {
            appContext?.state.applyingSticker = nil
        } else {
            guard let applyingSticker = appContext?.stickerService.fetchedResultsController.object(at: IndexPath(row: indexPath.row - 1, section: 0)) else { return }
            appContext?.state.applyingSticker = applyingSticker
        }
        tableView.reloadData()
    }
}

extension LMCameraViewStickerTableViewDelegate: LMDataServiceDelegate {
    func contentChanged(snapshot: NSDiffableDataSourceSnapshotReference, type: String) {
        guard type == String(describing: LMSticker.self) else { return }
        applySnapshotFrom(allStickerID: snapshot.itemIdentifiers as? [NSManagedObjectID] ?? [])
    }
}
