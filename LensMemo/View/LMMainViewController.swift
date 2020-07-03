//
//  LMMainViewController.swift
//  LensMemo-iOS
//
//  Created by Luke Yin on 2020-07-01.
//

import UIKit
import CoreData

class LMMainViewController: LMViewController {
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var topButtonStackView: UIStackView!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var menuTapToggleView: UIView!
    var menuTapToggleGesture: UITapGestureRecognizer?
    
    @IBOutlet weak var menuTableView: UITableView!
    
    var mainMenuDelegate: MainViewMenuTableViewDelegate?
    
    var state: State = .root {
        didSet {
            switch state{
            case .root:
                UIView.animate(withDuration: 0.3) {
                    self.menuView.transform = .identity
                    self.topView.transform = .identity
                    self.previewView.alpha = 0.5
                    self.topView.layer.shadowOpacity = 0.6
                    self.menuView.layer.shadowOpacity = 0.6
                }
            case .contentFullScreen:
                UIView.animate(withDuration: 0.3) {
                    self.menuView.transform = CGAffineTransform(translationX: -self.menuView.bounds.width, y: 0)
                    self.topView.transform = CGAffineTransform(translationX: 0, y: -self.topView.bounds.height)
                    self.previewView.alpha = 1.0
                    self.topView.layer.shadowOpacity = 0
                    self.menuView.layer.shadowOpacity = 0
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mainMenuDelegate = try? MainViewMenuTableViewDelegate(tableView: menuTableView, appContext: appContext)
        topView.layer.shadowColor = UIColor.black.cgColor
        topView.layer.shadowOffset = CGSize(width: 0, height: 0)
        topView.layer.shadowRadius = 16
        topView.layer.shadowOpacity = 0.6
        
        menuView.layer.shadowColor = UIColor.black.cgColor
        menuView.layer.shadowOffset = CGSize(width: 0, height: 0)
        menuView.layer.shadowRadius = 16
        menuView.layer.shadowOpacity = 0.6
        
        let menuTapToggleGesture = UITapGestureRecognizer(target: self, action: #selector(toggleMenuShowing))
        menuTapToggleView.addGestureRecognizer(menuTapToggleGesture)
        self.menuTapToggleGesture = menuTapToggleGesture
    }
    
    override func viewWillAppear(_ animated: Bool) {
        menuTableView.contentInset = UIEdgeInsets(top: topButtonStackView.bounds.height, left: 0, bottom: 0, right: 0)
        menuTableView.delegate = mainMenuDelegate
        menuTableView.dataSource = mainMenuDelegate
    }
    
    static func getInstance(appContext: LMAppContext) -> LMMainViewController {
        let mainViewController = LMMainViewController(nibName: String(describing: LMMainViewController.self), bundle: nil)
        mainViewController.appContext = appContext
        return mainViewController
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var shouldAutorotate: Bool {
        return true
    }
    
    @objc func toggleMenuShowing() {
        if self.state == .root {
            self.state = .contentFullScreen
        } else if self.state == .contentFullScreen {
            self.state = .root
        }
    }
    
    @IBAction func addSticker(_ sender: Any) {
        guard let newSticker = NSEntityDescription.insertNewObject(forEntityName: "LMSticker", into: appContext.storage.viewContext) as? LMSticker else { return }
        
        newSticker.name = "New Stciker"
        newSticker.id = UUID()
        newSticker.created = Date()
        
        try! appContext.storage.viewContext.save()
    }
    
    @IBAction func addNoteBook(_ sender: Any) {
        guard let newNoteBook = NSEntityDescription.insertNewObject(forEntityName: "LMNotebook", into: appContext.storage.viewContext) as? LMNotebook else { return }
        
        newNoteBook.color = "red"
        newNoteBook.created = Date()
        newNoteBook.id = UUID()
        newNoteBook.isCover = false
        newNoteBook.isHidden = false
        newNoteBook.modified = Date()
        newNoteBook.name = "New Notebook"
        
        try! appContext.storage.viewContext.save()
    }
}

extension LMMainViewController {
    enum State {
        case root
        case contentFullScreen
    }
}
