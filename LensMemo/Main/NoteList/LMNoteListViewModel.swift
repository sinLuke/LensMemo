//
//  LMNoteListViewModel.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-11.
//

import UIKit
import CoreData

class LMNoteListViewModel: ViewModel {
    var fetchedResultsController: NSFetchedResultsController<LMNote>
    var sections: [Section] = []
    var notes: [LMNote] = []
    
    init(fetchedResultsController: NSFetchedResultsController<LMNote>) {
        self.fetchedResultsController = fetchedResultsController
    }
    
    func build() {
        guard let section = fetchedResultsController.sections?.first, let notes = section.objects as? [LMNote] else { return }
        self.notes = notes
        let sortedNotes = Array(notes.sorted { (lhs, rhs) -> Bool in
            lhs.lastViewed ?? Date() > rhs.lastViewed ?? Date()
        }.prefix(10))

        let recentlyViewedSection = Section(notes: sortedNotes, header: "Recently Viewed", isHeadline: true)
        let allNotesSection = Section(notes: notes, header: "All notes", isHeadline: false)
        sections = [
            recentlyViewedSection,
            allNotesSection
        ]
    }
    
    struct Section {
        var notes: [LMNote]
        var header: String
        var isHeadline: Bool
        func getViewForCell(at indexPath: IndexPath, for collectionView: UICollectionView, appContext: LMAppContext) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: LMNoteCollectionViewCell.self), for: indexPath)
            if let cell = cell as? LMNoteCollectionViewCell {
                cell.configure(note: notes[indexPath.row], thumbnail: isHeadline ? false : true , appContext: appContext)
            }
            return cell
        }
        
        func getHeaderView(at indexPath: IndexPath, for collectionView: UICollectionView) -> UICollectionReusableView {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: String(describing: LMCollectionViewHeaderView.self), withReuseIdentifier: String(describing: LMCollectionViewHeaderView.self), for: indexPath)
            if let headerView = headerView as? LMCollectionViewHeaderView {
                headerView.configure(string: header)
            }
            return headerView
        }
    }
}

extension LMNoteListViewModel: LMDataServiceDelegate {
    func contentChanged(snapshot: NSDiffableDataSourceSnapshotReference, type: String) {
        build()
    }
}
