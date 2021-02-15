//
//  LMNoteListViewModel.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-11.
//

import UIKit
import CoreData

class LMNoteListViewModel: ViewModel {
    weak var appContext: LMAppContext?
    var fetchedResultsController: NSFetchedResultsController<LMNote>
    weak var delegate: ViewModelDelegate?
    var notes: [LMNote] = []
    var sortedBy: SortingMethod = .byCreateDate {
        didSet {
            build()
            delegate?.viewShouldUpdate()
        }
    }
    var sections: [Section] = []
    var sortedNotes: [NoteDateFomatter.Style: [LMNote]] = [:]
    var sortedStickerNotes: [LMSticker: [LMNote]] = [:]
    var sortedNotebookNotes: [LMNotebook: [LMNote]] = [:]
    
    var configuredByNotebook = true
    var isEditing: Bool = false {
        didSet {
            build()
            delegate?.viewShouldUpdate()
        }
    }
    
    var shiftKeyHolding: Bool = false {
        didSet {
            #if !targetEnvironment(macCatalyst)
            isEditing = true
            #endif
        }
    }
    
    var commandKeyHolding: Bool = false {
        didSet {
            #if !targetEnvironment(macCatalyst)
            isEditing = true
            #endif
        }
    }
    
    init(fetchedResultsController: NSFetchedResultsController<LMNote>, appContext: LMAppContext?, delegate: ViewModelDelegate?, configuredByNotebook: Bool) {
        self.fetchedResultsController = fetchedResultsController
        self.appContext = appContext
        self.delegate = delegate
        self.configuredByNotebook = configuredByNotebook
    }
    
    func build() {
        guard let section = fetchedResultsController.sections?.first, let notes = section.objects as? [LMNote] else { return }
        
        self.notes = notes
        sortedNotes = [:]
        sortedStickerNotes = [:]
        sortedNotebookNotes = [:]
        
        let allNotesSection: [Section]
        
        switch sortedBy {
        case .byCreateDate:
            allNotesSection = [Section.noteSection(notes: notes, header: "", headerColor: nil, isEditing: self.isEditing)]
        case .byLastViewed:
            notes.forEach { (note) in
                guard let date = note.lastViewed ?? note.created else { return }
                let noteDateFomatter = NoteDateFomatter()
                _ = noteDateFomatter.string(from: date)
                guard let style = noteDateFomatter.preferedStyle else { return }
                
                if sortedNotes[style] == nil {
                    sortedNotes[style] = [note]
                } else {
                    sortedNotes[style]?.append(note)
                }
            }
            
            allNotesSection = sortedNotes.keys.sorted { (lhs, rhs) -> Bool in
                lhs.rawValue < rhs.rawValue
            } .map { (style) in
                Section.noteSection(notes: sortedNotes[style] ?? [], header: style.localizedDescription(), headerColor: nil, isEditing: self.isEditing)
            }
        case .stickers:
            notes.forEach { (note) in
                let stickers = (note.stickers as? Set<LMSticker>) ?? Set<LMSticker>()
                Array(stickers).forEach { (sticker) in
                    if sortedStickerNotes[sticker] == nil {
                        sortedStickerNotes[sticker] = [note]
                    } else {
                        sortedStickerNotes[sticker]?.append(note)
                    }
                }
            }
            
            allNotesSection = sortedStickerNotes.keys.sorted { (lhs, rhs) -> Bool in
                lhs.name ?? "" < rhs.name ?? ""
            } .map { (sticker) in
                Section.noteSection(notes: sortedStickerNotes[sticker] ?? [], header: sticker.name ?? "?", headerColor: nil, isEditing: self.isEditing)
            }
        case .noteBook:
            notes.forEach { (note) in
                guard let notebook = note.notebook else { return }
                if sortedNotebookNotes[notebook] == nil {
                    sortedNotebookNotes[notebook] = [note]
                } else {
                    sortedNotebookNotes[notebook]?.append(note)
                }
            }
            
            allNotesSection = sortedNotebookNotes.keys.sorted { (lhs, rhs) -> Bool in
                lhs.created ?? Date() < rhs.created ?? Date()
            } .map { (notebook) in
                Section.noteSection(notes: sortedNotebookNotes[notebook] ?? [], header: notebook.name ?? "?", headerColor: LMNotebookDataService.NotebookColor(rawValue: notebook.color ?? "default")?.getColor() ?? .label, isEditing: self.isEditing)
            }
        }
        

        

        let actionItemSection = Section.actionItems(items: [
            buildSortingSegmentedControl(),
            buildEditButton(),
            buildDeleteButton()
            ].compactMap { $0 })
        sections = [
            actionItemSection
        ]
        sections.append(contentsOf: allNotesSection)
    }
    
    func buildActionSection() {
        let actionItemSection = Section.actionItems(items: [
            buildSortingSegmentedControl(),
            buildEditButton(),
            buildDeleteButton()
        ].compactMap { $0 })
        sections[0] = actionItemSection
    }
    
    func buildDeleteButton() -> ActionItem? {
        if isEditing && appContext?.state.selectedNotes.count ?? 0 > 0 {
            return .buttonItem(title: l("Delete \(appContext?.state.selectedNotes.count ?? 0) notes"), backgroundColor: .systemRed, textColor: .white, callBack: { [weak self] in
                (self?.appContext?.state.selectedNotes ?? []).forEach { (note) in
                    self?.appContext?.noteService.deleteNote(note: note)
                }
                try? self?.appContext?.storage.saveContext()
            })
        } else {
            return nil
        }
    }
    
    func buildSortingSegmentedControl() -> ActionItem? {
        let options: [String]
        if configuredByNotebook {
            options = ["Default", "Stickers", "Last Viewed"]
        } else {
            options = ["Default", "Notebook", "Last Viewed"]
        }
        
        let selectedInt = { () -> Int in
            switch sortedBy {
            case .byCreateDate: return 0
            case .byLastViewed: return 2
            case .noteBook: return 1
            case .stickers: return 1
            }
        }()
        return .segmentedControlItem(options: options, seletingIndex: selectedInt) { [weak self] (option) in
            switch option {
            case 1:
                self?.sortedBy = self?.configuredByNotebook == true ? .stickers : .noteBook
            case 2:
                self?.sortedBy = .byLastViewed
            default:
                self?.sortedBy = .byCreateDate
            }
        }
    }
    
    func buildEditButton() -> ActionItem? {
        #if targetEnvironment(macCatalyst)
        return nil
        #else
        if isEditing {
            return .buttonItem(title: l("Done"), backgroundColor: .systemBlue, textColor: .white, callBack: { [weak self] in
                self?.isEditing = false
                self?.appContext?.selectedNotes(notes: [])
            })
        } else {
            return .buttonItem(title: l("Edit"), backgroundColor: .systemFill, textColor: .label, callBack: { [weak self] in
                self?.isEditing = true
            })
        }
        #endif
    }
    
    enum ActionItem {
        case buttonItem(title: String, backgroundColor: UIColor, textColor: UIColor, callBack: () -> ())
        case segmentedControlItem(options: [String], seletingIndex: Int, callBack: (Int) -> ())
    }
    
    enum Section {
        case noteSection(notes: [LMNote], header: String, headerColor: UIColor?, isEditing: Bool)
        case actionItems(items: [ActionItem])
        func getViewForCell(at indexPath: IndexPath, for collectionView: UICollectionView, appContext: LMAppContext) -> UICollectionViewCell {
            switch self {
            case let .noteSection(notes, _, _, isEditing):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: LMNoteCollectionViewCell.self), for: indexPath)
                if let cell = cell as? LMNoteCollectionViewCell {
                    cell.configure(note: notes[indexPath.row], isEditing: isEditing, appContext: appContext)
                }
                return cell
            case let .actionItems(items):
                let item = items[indexPath.row]
                switch item {
                case let .buttonItem(title, backgroundColor, textColor, _):
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: LMNoteActionButtonCollectionViewCell.self), for: indexPath)
                    if let cell = cell as? LMNoteActionButtonCollectionViewCell {
                        cell.configure(title: title, backgroundColor: backgroundColor, textColor: textColor)
                    }
                    return cell
                case let .segmentedControlItem(options, seletingIndex, callBack):
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: LMNoteActionSegmentedControlCollectionViewCell.self), for: indexPath)
                    if let cell = cell as? LMNoteActionSegmentedControlCollectionViewCell {
                        cell.configure(options: options, seletingIndex: seletingIndex, callBack: callBack)
                    }
                    return cell
                }
            }
        }
        
        func getHeaderView(at indexPath: IndexPath, for collectionView: UICollectionView) -> UICollectionReusableView {
            switch self {
            case let .noteSection(_, header, headerColor, _):
                let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: String(describing: LMCollectionViewHeaderView.self), withReuseIdentifier: String(describing: LMCollectionViewHeaderView.self), for: indexPath)
                if let headerView = headerView as? LMCollectionViewHeaderView {
                    headerView.configure(header: header, headerColor: headerColor)
                }
                return headerView
            default:
                return UICollectionReusableView()
            }
        }
        
        func didSelected(indexPath: IndexPath) {
            switch self {
            case let .actionItems(items):
                let item = items[indexPath.row]
                switch item {
                case let .buttonItem(_, _, _, callBack):
                    callBack()
                default:
                    return
                }
            default: return
            }
        }
    }
}

extension LMNoteListViewModel: LMDataServiceDelegate {
    func contentChanged(snapshot: NSDiffableDataSourceSnapshotReference, type: String) {
        build()
    }
    
    enum SortingMethod {
        case stickers
        case byCreateDate
        case byLastViewed
        case noteBook
    }
}
