//
//  LMMainViewMenuNoteLayout.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-11.
//

import UIKit

class LMMainViewMenuNoteLayout {
    weak var viewModel: LMMainViewMenuNoteViewModel?
    
    func getLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            let spacing: CGFloat = 2
            let rowCount = max(1, Int(layoutEnvironment.container.contentSize.width / 87))
            let numberOfSections = self?.viewModel?.sections.count ?? 3
            
            let headlineItem = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .fractionalHeight(1.0)))
            headlineItem.contentInsets = NSDirectionalEdgeInsets(top: spacing, leading: spacing, bottom: spacing, trailing: spacing)
            
            let compactItem = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0 / CGFloat(rowCount)),
                                                   heightDimension: .fractionalHeight(1.0)))
            compactItem.contentInsets = NSDirectionalEdgeInsets(top: spacing, leading: spacing, bottom: spacing, trailing: spacing)
            
            let headlineGroup = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.9),
                    heightDimension: .fractionalWidth(0.6)),
                subitems: [headlineItem])
            
            let compactGroup = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                   heightDimension: .fractionalWidth(1.0 / CGFloat(rowCount))),
                subitem: compactItem, count: rowCount)
            
            let section = NSCollectionLayoutSection(group: sectionIndex == (numberOfSections - 1) ? compactGroup : headlineGroup)
            
            let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                          heightDimension: .estimated(44))
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerFooterSize,
                elementKind: String(describing: LMCollectionViewHeaderView.self), alignment: .top)
            
            section.boundarySupplementaryItems = [sectionHeader]
            section.orthogonalScrollingBehavior = sectionIndex == (numberOfSections - 1) ? .none : .continuous
            section.contentInsets = NSDirectionalEdgeInsets(top: spacing*2, leading: spacing, bottom: spacing, trailing: spacing)
            
            return section
        }
    }
}
