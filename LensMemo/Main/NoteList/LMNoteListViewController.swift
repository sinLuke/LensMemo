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
        mainViewMenuNoteListViewController.viewModel = LMNoteListViewModel(fetchedResultsController: fetchedResultsController)
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
        mainViewMenuNoteListViewController.viewModel = LMNoteListViewModel(fetchedResultsController: fetchedResultsController)
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
        
        self.viewModel = LMNoteListViewModel(fetchedResultsController: fetchedResultsController)
        
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
        collectionView.insetsLayoutMarginsFromSafeArea = false
        layout.viewModel = viewModel
        collectionView.register(UINib(nibName: String(describing: LMNoteCollectionViewCell.self), bundle: nil), forCellWithReuseIdentifier: String(describing: LMNoteCollectionViewCell.self))
        collectionView.register(LMCollectionViewHeaderView.self, forSupplementaryViewOfKind: String(describing: LMCollectionViewHeaderView.self), withReuseIdentifier: String(describing: LMCollectionViewHeaderView.self))
        navigationController?.navigationBar.tintColor = LMNotebookDataService.NotebookColor(rawValue: notebook?.color ?? "default")?.getColor() ?? .label
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel?.build()
        collectionView.reloadData()
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
        appContext.mainViewController.hideSnackbarIfCan()
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
        let note = viewModel!.sections[indexPath.section].notes[indexPath.row]
        let noteEnclosure = LMNoteEnclosure(note: note, appContext: appContext)
        let dragItem = UIDragItem(itemProvider: NSItemProvider(object: noteEnclosure))
        dragItem.localObject = note
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.sections[section].notes.count ?? 0
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
        let note = viewModel!.sections[indexPath.section].notes[indexPath.row]
        appContext.selectedNote(note: note)
        print("didSelectItemAt \(indexPath)")
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        print("didDeselectItemAt \(indexPath)")
    }
}
