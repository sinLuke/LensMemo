//
//  LMNoteListViewController.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-04.
//

import UIKit

class LMNoteListViewController: LMViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var emptyLabel: UILabel!
    var notebook: LMNotebook?
    var sticker: LMSticker?
    var thatsOnCover: Bool = false
    var viewModel: LMNoteListViewModel?
    var layout = LMNoteListLayout()
    var lastSelectedIndexPath: IndexPath?
    
    static func getInstance(appContext: LMAppContext, notebook: LMNotebook?, thatsOnCover: Bool) -> LMNoteListViewController {
        let mainViewMenuNoteListViewController = LMNoteListViewController(nibName: String(describing: LMNoteListViewController.self), bundle: nil)
        mainViewMenuNoteListViewController.appContext = appContext
        mainViewMenuNoteListViewController.sticker = nil
        mainViewMenuNoteListViewController.notebook = notebook
        mainViewMenuNoteListViewController.thatsOnCover = thatsOnCover
        mainViewMenuNoteListViewController.title = notebook?.name ?? "Notebook"
        guard notebook != nil, let fetchedResultsController = appContext.noteService.fetchedResultsController(noteBook: notebook, sticker: nil, thatsOnCover: thatsOnCover) else {
            return mainViewMenuNoteListViewController
        }
        mainViewMenuNoteListViewController.viewModel = LMNoteListViewModel(fetchedResultsController: fetchedResultsController, appContext: appContext, delegate: mainViewMenuNoteListViewController, configuredByNotebook: true)
        return mainViewMenuNoteListViewController
    }
    
    static func getInstance(appContext: LMAppContext, sticker: LMSticker?) -> LMNoteListViewController {
        let mainViewMenuNoteListViewController = LMNoteListViewController(nibName: String(describing: LMNoteListViewController.self), bundle: nil)
        mainViewMenuNoteListViewController.appContext = appContext
        mainViewMenuNoteListViewController.sticker = sticker
        mainViewMenuNoteListViewController.notebook = nil
        mainViewMenuNoteListViewController.thatsOnCover = false
        mainViewMenuNoteListViewController.title = sticker?.name ?? "Sticker"
        guard sticker != nil, let fetchedResultsController = appContext.noteService.fetchedResultsController(noteBook: nil, sticker: sticker, thatsOnCover: false) else {
            return mainViewMenuNoteListViewController
        }
        mainViewMenuNoteListViewController.viewModel = LMNoteListViewModel(fetchedResultsController: fetchedResultsController, appContext: appContext, delegate: mainViewMenuNoteListViewController, configuredByNotebook: false)
        return mainViewMenuNoteListViewController
    }
    
    func update() {
        update(notebook: self.notebook, sticker: self.sticker, thatsOnCover: self.thatsOnCover)
    }
    
    func update(notebook: LMNotebook?, sticker: LMSticker?, thatsOnCover: Bool) {
        self.notebook = notebook
        self.sticker = sticker
        self.thatsOnCover = thatsOnCover
        self.title = notebook?.name ?? sticker?.name ?? "Notebook"
        
        guard isViewLoaded, let fetchedResultsController = appContext.noteService.fetchedResultsController(noteBook: notebook, sticker: sticker, thatsOnCover: thatsOnCover) else {
            return
        }
        
        self.viewModel = LMNoteListViewModel(fetchedResultsController: fetchedResultsController, appContext: appContext, delegate: self, configuredByNotebook: notebook != nil)
        
        layout.viewModel = viewModel
        
        viewModel?.build()
        collectionView.reloadData()
        appContext.forcusOn(notes: viewModel?.notes ?? [])
        
        configure()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.collectionViewLayout = layout.getLayout()
        collectionView.insetsLayoutMarginsFromSafeArea = true
        collectionView.allowsMultipleSelection = true

        layout.viewModel = viewModel
        viewModel?.delegate = self
        collectionView.register(UINib(nibName: String(describing: LMNoteCollectionViewCell.self), bundle: nil), forCellWithReuseIdentifier: String(describing: LMNoteCollectionViewCell.self))
        collectionView.register(LMCollectionViewHeaderView.self, forSupplementaryViewOfKind: String(describing: LMCollectionViewHeaderView.self), withReuseIdentifier: String(describing: LMCollectionViewHeaderView.self))
        collectionView.register(UINib(nibName: String(describing: LMNoteActionButtonCollectionViewCell.self), bundle: nil), forCellWithReuseIdentifier: String(describing: LMNoteActionButtonCollectionViewCell.self))
        collectionView.register(UINib(nibName: String(describing: LMNoteActionSegmentedControlCollectionViewCell.self), bundle: nil), forCellWithReuseIdentifier: String(describing: LMNoteActionSegmentedControlCollectionViewCell.self))
        
        navigationController?.navigationBar.tintColor = LMNotebookDataService.NotebookColor(rawValue: notebook?.color ?? "default")?.getColor() ?? .label
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel?.build()
        appContext.forcusOn(notes: viewModel?.notes ?? [])
        
        configure()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func configure() {
        if notebook == nil && sticker == nil {
            emptyLabel.text = "Please select a notebook"
            collectionView.isHidden = true
        } else if notebook?.notes?.count == 0 || sticker?.notes?.count == 0 {
            emptyLabel.text = "No notes found"
            collectionView.isHidden = true
        } else {
            emptyLabel.text = nil
            collectionView.isHidden = false
        }
    }
    
    override func appStateDidSet() {
        if isViewLoaded {
            collectionView.reloadData()
        }
    }
}

extension LMNoteListViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        if let notebook = self.notebook {
            appContext.noteBookService.createNotesFromDraggedImage(coordinator: coordinator, in: notebook)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard session.localDragSession == nil, self.notebook != nil else {
            return .init(operation: .forbidden)
        }
        return UICollectionViewDropProposal(
            operation: .copy,
            intent: .insertAtDestinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let section = viewModel?.sections[indexPath.section] else { return [] }
        switch section {
        case let .noteSection(notes, _, _, _):
            let note = notes[indexPath.row]
            let noteEnclosure = LMNoteEnclosure(note: note, appContext: appContext)
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: noteEnclosure))
            dragItem.localObject = note
            return [dragItem]
        default: return []
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = viewModel?.sections[section] else { return 0 }
        switch section {
        case let .noteSection(notes, _, _, _):
            return notes.count
        case let .actionItems(items):
            return items.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return viewModel!.sections[indexPath.section].getViewForCell(at: indexPath, for: collectionView, appContext: appContext)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel?.sections.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return viewModel!.sections[indexPath.section].getHeaderView(at: indexPath, for: collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let section = viewModel?.sections[indexPath.section] else { return }
        
        var changedIndexPath: [IndexPath] = []

        switch section {
        case let .noteSection(notes, _, _, _):
            DispatchQueue.global().async {
                let selectedNote = notes[indexPath.row]
                if (self.viewModel?.configuredByNotebook == true && self.appContext.state.selectedNotes.last?.notebook != selectedNote.notebook) || (self.sticker != nil && self.appContext.state.selectedNotes.last?.stickers?.contains(self.sticker!) == false) {
                    self.appContext.selectedNotes(notes: [])
                }
                
                if self.viewModel?.isEditing == true || self.viewModel?.commandKeyHolding == true {
                    changedIndexPath.append(indexPath)
                    self.appContext.toggleSelectNote(note: selectedNote, shouldHideMenuView: false)
                } else if self.viewModel?.shiftKeyHolding == true {
                    var closestIndexPathRow = 0
                    if self.lastSelectedIndexPath?.section == indexPath.section {
                        closestIndexPathRow = self.lastSelectedIndexPath?.row ?? 0
                    }
                    
                    for row in min(closestIndexPathRow, indexPath.row) ... max(closestIndexPathRow, indexPath.row) {
                        if !notes.indices.contains(row) { return }
                        changedIndexPath.append(IndexPath(item: row, section: indexPath.section))
                        self.appContext.addSelectNote(note: notes[row], shouldHideMenuView: false)
                    }
                } else {
                    changedIndexPath.append(indexPath)
                    self.appContext.selectedNotes(notes: [selectedNote])
                }
                
                if self.lastSelectedIndexPath?.section == indexPath.section || self.lastSelectedIndexPath == nil {
                    self.lastSelectedIndexPath = indexPath
                } else {
                    self.lastSelectedIndexPath = nil
                }
                
                main {
                    self.viewModel?.buildActionSection()
                    collectionView.reloadData()
                }
            }

            
        default: section.didSelected(indexPath: indexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        guard let section = viewModel?.sections[indexPath.section] else { return nil }
        switch section {
        case let .noteSection(notes, _, _, _):
            let note = notes[indexPath.item]
            appContext.addSelectNote(note: note)
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: noteMenuProvider)
        default: return nil
        }
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        presses.forEach { (press) in
            if press.key?.keyCode.rawValue == 227 {
                viewModel?.commandKeyHolding = true
            }

            if press.key?.keyCode.rawValue == 225 {
                viewModel?.shiftKeyHolding = true
            }
        }
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        presses.forEach { (press) in
            if press.key?.keyCode.rawValue == 227 {
                viewModel?.commandKeyHolding = false
            }

            if press.key?.keyCode.rawValue == 225 {
                viewModel?.shiftKeyHolding = false
            }
        }
    }
}

extension LMNoteListViewController: ViewModelDelegate {
    func viewShouldUpdate() {
        collectionView.reloadData()
    }
}

extension LMNoteListViewController {
    func noteMenuProvider(_: [UIMenuElement]) -> UIMenu? {
        let coverAction = UIAction(title: "add_to_cover", image: nil) { [weak self] _ in
            self?.appContext.state.selectedNotes.forEach { $0.onCover = true }
            try? self?.appContext.storage.saveContext()
        }
        
        var notebookMenuItemList: [UIMenuElement] = []
        
        if let notebookList = self.appContext.noteBookService.fetchedResultsController.fetchedObjects, notebookList.count > 0 {
            notebookList.forEach { anyNotebook in
                notebookMenuItemList.append(
                    UIAction(title: anyNotebook.name ?? "untitle_notebook",
                             image: nil)
                    { [weak self] _ in
                        self?.appContext.state.selectedNotes.forEach { $0.notebook = anyNotebook }
                        try? self?.appContext.storage.saveContext()
                })
            }
        }
        
        var stickerMenuItemList: [UIMenuElement] = []
        
        if let stickerList = self.appContext.stickerService.fetchedResultsController.fetchedObjects, stickerList.count > 0 {
            stickerList.forEach { anySticker in
                stickerMenuItemList.append(
                    UIAction(title: anySticker.name ?? "?",
                             image: nil)
                    { [weak self] _ in
                        self?.appContext.state.selectedNotes.forEach {
                            let newSet = NSMutableSet(set: $0.stickers ?? [])
                            if $0.stickers?.contains(anySticker) == false {
                                newSet.add(anySticker)
                            }
                            $0.stickers = newSet
                        }
                        try? self?.appContext.storage.saveContext()
                })
            }
        }
        
        let notebookAction = UIMenu(title: "move_to_notebook", image: nil, identifier: nil, children: notebookMenuItemList)
        
        let stickerAction = UIMenu(title: "add_sticker", image: nil, identifier: nil, children: stickerMenuItemList)
        
        let moveToAction = UIMenu(title: "move_to", image: nil, identifier: nil, options: .displayInline, children: [notebookAction, stickerAction, coverAction])
        
        #if !targetEnvironment(macCatalyst)
        let showDetailAction = UIAction(title: "detail",
                                        image: nil)
        { [weak self] _ in
            guard let self = self else { return }
            let imageDetailViewController = LMImageDetailViewController.getInstance(appContext: self.appContext)
            imageDetailViewController.loadView()
            imageDetailViewController.viewDidLoad()
            imageDetailViewController.configure(note: self.appContext.state.selectedNotes.last)
            self.present(imageDetailViewController, animated: true, completion: nil)
        }
        #else
        let showDetailAction: UIMenuElement? = nil
        #endif
        
        let deleteAction = UIAction(title: "delete",
                                    image: UIImage(systemName: "trash.fill"))
        { [weak self] _ in
            self?.appContext.state.selectedNotes.forEach {
                self?.appContext.noteService.deleteNote(note: $0)
            }
            try? self?.appContext.storage.saveContext()
            self?.collectionView.reloadData()
        }
        
        let shareAction = UIAction(title: "share", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
            return
        }
        
        #if targetEnvironment(macCatalyst)
        let exportAction = UIAction(title: "export", image: UIImage(systemName: "square.and.arrow.down")) { [weak self] _ in
            guard let appContext = self?.appContext, let notes = self?.appContext.state.selectedNotes, notes.count > 0 else { return }
            let alertViewController = UIAlertController(title: l("exporting_images"), message: nil, preferredStyle: .alert)
            
            var progress: Progress? = nil
            progress = appContext.imageService.getImages(for: notes.compactMap { $0.id }) { (results) in
                var imageList: [UIImage] = []
                var errorList: [Error] = []
                results.forEach {
                    $0.see { (image) in
                        imageList.append(image)
                    } ifNot: { (error) in
                        errorList.append(error)
                    }
                }
                
                LMPhotoExportAndImportService.shared.saveImage(images: imageList) { (savingErrorList) in
                    if alertViewController.isBeingPresented {
                        alertViewController.dismiss(animated: true, completion: nil)
                    }
                    
                    if progress?.isCancelled != false { return }

                    errorList.append(contentsOf: savingErrorList)
                    var alert: LMAlertViewViewController?
                    alert = LMAlertViewViewController.getInstance(data: LMAlertViewViewController.Data(allowDismiss: true, icon: UIImage(systemName: "exclamationmark.triangle.fill"), color: .systemRed, title: "finish_with_error", messages: errorList.map { "error: \($0.localizedDescription)" }, buttons: [LMAlertViewViewController.Button(title: "OK", validateInput: false, onTap: { [weak alert] in
                        alert?.dismiss(animated: true, completion: nil)
                    })]))
                    if let alert = alert {
                        self?.present(alert, animated: true, completion: nil)
                    }
                }
            }

            
            alertViewController.addAction(UIAlertAction(title: l("cancel"), style: .cancel, handler: { (_) in
                progress?.cancel()
                alertViewController.dismiss(animated: true, completion: nil)
            }))
            
            let progressBar = UIProgressView(progressViewStyle: .default)
            progressBar.observedProgress = progress
            progressBar.frame = CGRect(x: 10, y: 70, width: 250, height: 0)
            alertViewController.view.addSubview(progressBar)
            
            self?.present(alertViewController, animated: true, completion: nil)
        }
        #else
        
        let exportAction = UIAction(title: "add_to_album", image: UIImage(systemName: "square.and.arrow.down")) { [weak self] _ in
            guard let appContext = self?.appContext, let notes = self?.appContext.state.selectedNotes, notes.count > 0 else { return }
            let alertViewController = UIAlertController(title: l("exporting_images"), message: l("exporting_\(notes.count)_images\n"), preferredStyle: .alert)
            
            var progress = Progress(totalUnitCount: 100)
            let subProgress = appContext.imageService.getImages(for: notes.compactMap { $0.id }) { (results) in
                var imageList: [UIImage] = []
                var errorList: [Error] = []
                results.forEach {
                    $0.see { (image) in
                        imageList.append(image)
                    } ifNot: { (error) in
                        errorList.append(error)
                    }
                }
                LMPhotoExportAndImportService.checkPermission { flag in
                    if !flag {
                        alertViewController.dismiss(animated: true, completion: {
                            progress.cancel()
                        })
                    }
                    LMPhotoExportAndImportService.shared.saveImage(images: imageList) { _ in
                        main {
                            progress.completedUnitCount = 100
                            alertViewController.dismiss(animated: true, completion: {
                                var alert: LMAlertViewViewController?
                                alert = LMAlertViewViewController.getInstance(data: LMAlertViewViewController.Data(allowDismiss: true, icon: UIImage(systemName: "exclamationmark.triangle.fill"), color: .systemRed, title: "finish_with_error", messages: errorList.map { "error: \($0.localizedDescription)" }, buttons: [LMAlertViewViewController.Button(title: "OK", validateInput: false, onTap: { [weak alert] in
                                    alert?.dismiss(animated: true, completion: nil)
                                })]))
                                if let alert = alert {
                                    self?.present(alert, animated: true, completion: nil)
                                }
                            })
                        }
                    }
                }
            }
            
            progress.addChild(subProgress, withPendingUnitCount: 90)
            
            alertViewController.addAction(UIAlertAction(title: l("cancel"), style: .cancel, handler: { (_) in
                progress.cancel()
                alertViewController.dismiss(animated: true, completion: nil)
            }))
            
            let progressBar = UIProgressView(progressViewStyle: .default)
            progressBar.observedProgress = progress
            progressBar.frame = CGRect(x: 20, y: 75, width: 230, height: 64)
            alertViewController.view.addSubview(progressBar)
            
            self?.present(alertViewController, animated: true, completion: nil)
        }
        #endif
        
        let actions = [showDetailAction, deleteAction, shareAction, exportAction, moveToAction].compactMap { $0 }
        
        // We generate a new menu with our two actions
        return UIMenu(title: "Actions", image: nil, identifier: nil, options: .displayInline, children: actions)
    }
}
