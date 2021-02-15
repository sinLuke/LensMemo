//
//  LMStickerSelectionLayout.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-08-22.
//

import UIKit

class LMStickerSelectionLayout {
    func getLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout {(sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            #if targetEnvironment(macCatalyst)
            let rowCount = max(1, Int(layoutEnvironment.container.contentSize.width / 36))
            #else
            let rowCount = max(1, Int(layoutEnvironment.container.contentSize.width / 54))
            #endif
            
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0 / CGFloat(rowCount)),
                                                   heightDimension: .fractionalHeight(1.0)))
            item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                   heightDimension: .fractionalWidth(1.0 / CGFloat(rowCount))),
                subitem: item, count: rowCount)
            return NSCollectionLayoutSection(group: group)
        }
    }
}
