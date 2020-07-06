//
//  LMMainViewMenuNoteListViewController.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-04.
//

import UIKit

class LMMainViewMenuNoteListViewController: LMViewController {
    @IBOutlet weak var tableView: UITableView!
    var notebook: LMNotebook?
    var thatsOnCover: Bool = false
    var mainMenuNoteListDelegate: MainViewMenuNoteListTableViewDelegate?

    static func getInstance(appContext: LMAppContext) -> LMMainViewMenuNoteListViewController {
        let mainViewMenuNoteListViewController = LMMainViewMenuNoteListViewController(nibName: String(describing: LMMainViewMenuNoteListViewController.self), bundle: nil)
        mainViewMenuNoteListViewController.appContext = appContext
        return mainViewMenuNoteListViewController
    }
    
    override func viewDidLoad() {
        mainMenuNoteListDelegate = try? MainViewMenuNoteListTableViewDelegate(tableView: tableView, appContext: appContext, notebook: notebook, thatsOnCover: thatsOnCover)
        tableView.delegate = mainMenuNoteListDelegate
        tableView.dataSource = mainMenuNoteListDelegate
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = notebook?.name ?? "LensMemo"
        if mainMenuNoteListDelegate?.notebook != self.notebook {
            tableView.reloadData()
            viewDidLoad()
        }
    }
}
