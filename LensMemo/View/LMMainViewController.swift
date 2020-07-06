//
//  LMMainViewController.swift
//  LensMemo-iOS
//
//  Created by Luke Yin on 2020-07-01.
//

import UIKit
import CoreData

class LMMainViewController: LMViewController {
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var menuTapToggleView: UIView!
    var menuTapToggleGesture: UITapGestureRecognizer?
    
    var state: State = .root {
        didSet {
            switch state{
            case .root:
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                    self.menuView.transform = .identity
                    self.menuView.layer.shadowOpacity = 0.6
                })
            case .contentFullScreen:
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                    self.menuView.transform = CGAffineTransform(translationX: -self.menuView.bounds.width, y: 0)
                    self.menuView.layer.shadowOpacity = 0
                })
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        menuView.layer.shadowColor = UIColor.black.cgColor
        menuView.layer.shadowOffset = CGSize(width: 0, height: 0)
        menuView.layer.shadowRadius = 16
        menuView.layer.shadowOpacity = 0.6
        
        let menuTapToggleGesture = UITapGestureRecognizer(target: self, action: #selector(toggleMenuShowing))
        menuTapToggleView.addGestureRecognizer(menuTapToggleGesture)
        self.menuTapToggleGesture = menuTapToggleGesture
        
        addSubViewConreoller(appContext.mainViewMenuViewNavigationController, in: menuView)
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
}

extension LMMainViewController {
    enum State {
        case root
        case contentFullScreen
    }
}
