//
//  LMMainViewMenuNoteListViewController.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-04.
//

import UIKit

class LMMainViewMenuNoteListViewController: LMViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    var notebook: LMNotebook!
    var thatsOnCover: Bool = false
    var viewModel: LMMainViewMenuNoteViewModel!
    var layout = LMMainViewMenuNoteLayout()

    static func getInstance(appContext: LMAppContext, notebook: LMNotebook, thatsOnCover: Bool) -> LMMainViewMenuNoteListViewController? {
        let mainViewMenuNoteListViewController = LMMainViewMenuNoteListViewController(nibName: String(describing: LMMainViewMenuNoteListViewController.self), bundle: nil)
        mainViewMenuNoteListViewController.appContext = appContext
        mainViewMenuNoteListViewController.notebook = notebook
        mainViewMenuNoteListViewController.thatsOnCover = thatsOnCover
        mainViewMenuNoteListViewController.title = notebook.name
        guard let fetchedResultsController = appContext.noteService.fetchedResultsController(noteBook: notebook, thatsOnCover: thatsOnCover) else {
            return nil
        }
        mainViewMenuNoteListViewController.viewModel = LMMainViewMenuNoteViewModel(fetchedResultsController: fetchedResultsController)
        return mainViewMenuNoteListViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.collectionViewLayout = layout.getLayout()
        layout.viewModel = viewModel
        collectionView.register(UINib(nibName: String(describing: LMNoteCollectionViewCell.self), bundle: nil), forCellWithReuseIdentifier: String(describing: LMNoteCollectionViewCell.self))
        collectionView.register(LMCollectionViewHeaderView.self, forSupplementaryViewOfKind: String(describing: LMCollectionViewHeaderView.self), withReuseIdentifier: String(describing: LMCollectionViewHeaderView.self))
        navigationController?.navigationBar.tintColor = LMNotebookDataService.NotebookColor(rawValue: notebook.color ?? "default")?.getColor() ?? .label
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.build()
        appContext.forcusOn(notes: viewModel.notes)
    }
}

extension LMMainViewMenuNoteListViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.sections[section].notes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return viewModel.sections[indexPath.section].getViewForCell(at: indexPath, for: collectionView, appContext: appContext)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return viewModel.sections[indexPath.section].getHeaderView(at: indexPath, for: collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let note = viewModel.sections[indexPath.section].notes[indexPath.row]
        appContext.selectedNote(note: note)
    }
}
