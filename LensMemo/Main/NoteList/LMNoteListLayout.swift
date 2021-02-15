//
//  LMNoteListLayout.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-11.
//

import UIKit

class LMNoteListLayout {
    weak var viewModel: LMNoteListViewModel?
    let spacing: CGFloat = 2
    
    func getControlListGroup() -> NSCollectionLayoutGroup {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(40)), subitems: [item])
        return group
    }
    
    func getCompactCellGroup(itemCount: Int) -> NSCollectionLayoutGroup {
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0 / CGFloat(itemCount)), heightDimension: .fractionalHeight(1.0)))
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .fractionalWidth(1.0 / CGFloat(itemCount))),
            subitem: item, count: itemCount)
        return group
    }
    
    func getLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            guard let self = self, let viewModel = self.viewModel else { return nil }
            let itemCount = max(1, Int(layoutEnvironment.container.contentSize.width / 87))
            
            let section: NSCollectionLayoutSection
            if sectionIndex == 0 {
                section = NSCollectionLayoutSection(group: self.getControlListGroup())
            } else {
                if viewModel.sortedBy == .byCreateDate {
                    section = NSCollectionLayoutSection(group: self.getCompactCellGroup(itemCount: itemCount))
                } else {
                    section = NSCollectionLayoutSection(group: self.getCompactCellGroup(itemCount: itemCount))
                    let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(44))
                    let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                        layoutSize: headerFooterSize,
                        elementKind: String(describing: LMCollectionViewHeaderView.self), alignment: .top)
                    section.boundarySupplementaryItems = [sectionHeader]
                }
            }

            section.contentInsets = NSDirectionalEdgeInsets(top: self.spacing * 2, leading: self.spacing, bottom: self.spacing, trailing: self.spacing)
            
            return section
        }
    }
}
