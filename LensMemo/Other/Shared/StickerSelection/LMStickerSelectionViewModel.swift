//
//  LMStickerSelectionViewModel.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-08-22.
//

import UIKit
import CoreData

class LMStickerSelectionViewModel: ViewModel {
    var stickers: [LMSticker] {
        appContext.stickerService.fetchedResultsController.fetchedObjects ?? []
    }
    let appContext: LMAppContext
    let note: LMNote
    
    init(appContext: LMAppContext, note: LMNote) {
        self.appContext = appContext
        self.note = note
    }
    
    func getViewForCell(at indexPath: IndexPath, for collectionView: UICollectionView, appContext: LMAppContext) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: LMStickerSelectionCollectionViewCell.self), for: indexPath)
        if let cell = cell as? LMStickerSelectionCollectionViewCell {
            cell.configure(note: note, sticker: stickers[indexPath.item])
        }
        return cell
    }
}

extension LMStickerSelectionViewModel: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stickers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return getViewForCell(at: indexPath, for: collectionView, appContext: appContext)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        let newSet = NSMutableSet(set: note.stickers ?? [])
        if note.stickers?.contains(stickers[indexPath.item]) == true {
            newSet.remove(stickers[indexPath.item])
        } else {
            newSet.add(stickers[indexPath.item])
        }
        note.stickers = newSet
        collectionView.reloadData()
    }
}
