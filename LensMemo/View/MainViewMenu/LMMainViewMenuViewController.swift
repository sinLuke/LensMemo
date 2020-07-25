//
//  LMMainViewMenuViewController.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-04.
//

import UIKit

class LMMainViewMenuViewController: LMViewController {
    @IBOutlet weak var tableView: UITableView!
    var mainMenuDelegate: LMMainViewMenuTableViewDelegate?

    static func getInstance(appContext: LMAppContext) -> LMMainViewMenuViewController {
        let mainViewMenuController = LMMainViewMenuViewController(nibName: String(describing: LMMainViewMenuViewController.self), bundle: nil)
        mainViewMenuController.appContext = appContext
        return mainViewMenuController
    }
    
    override func viewDidLoad() {
        tableView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0)
        mainMenuDelegate = try? LMMainViewMenuTableViewDelegate(tableView: tableView, appContext: appContext)
        title = "LensMemo"
        let backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backBarButtonItem
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData()
    }
}
