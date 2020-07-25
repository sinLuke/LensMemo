//
//  LMMainViewController.swift
//  LensMemo-iOS
//
//  Created by Luke Yin on 2020-07-01.
//

import UIKit
import CoreData

class LMMainViewController: LMViewController {
    @IBOutlet weak var previewCollectionView: UICollectionView!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var menuTapToggleView: UIView!
    @IBOutlet weak var edgeMenuSwipeView: UIView!
    @IBOutlet weak var menuButtonContainerView: UIVisualEffectView!
    @IBOutlet weak var cameraButtonContainerView: UIVisualEffectView!
    @IBOutlet weak var statusBarGradientView: UIGradientView!
    
    var previewLayout = LMMainViewPreviewLayout()
    var menuTapToggleGesture: UITapGestureRecognizer?
    var menuEdgeSwipeGesture: UIScreenEdgePanGestureRecognizer?
    var previewViewModel: LMMainViewPreviewViewModel!
    
    var dynamicGradientColor = UIColor(dynamicProvider: { (trait) -> UIColor in
        if trait.userInterfaceStyle == .dark {
            return .clear
        } else {
            return UIColor.white.withAlphaComponent(0.5)
        }
    })
    
    var state: State = .root {
        didSet {
            switch state{
            case .root:
                edgeMenuSwipeView.isHidden = true
                menuTapToggleView.isHidden = false
                self.statusBarGradientView.alpha = 0.0
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                    self.menuView.transform = .identity
                    self.menuView.layer.shadowOpacity = 0.6
                    self.statusBarGradientView.alpha = 1.0
                    self.setNeedsStatusBarAppearanceUpdate()
                })
            case .contentFullScreen:
                edgeMenuSwipeView.isHidden = false
                menuTapToggleView.isHidden = true
                self.statusBarGradientView.alpha = 1.0
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                    self.menuView.transform = CGAffineTransform(translationX: -self.menuView.bounds.width, y: 0)
                    self.menuView.layer.shadowOpacity = 0
                    self.statusBarGradientView.alpha = 0.0
                    self.setNeedsStatusBarAppearanceUpdate()
                })
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        print("here")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        menuView.layer.shadowColor = UIColor.black.cgColor
        menuView.layer.shadowOffset = CGSize(width: 0, height: 0)
        menuView.layer.shadowRadius = 16
        menuView.layer.shadowOpacity = 0.6
        
        menuButtonContainerView.layer.cornerRadius = 19
        cameraButtonContainerView.layer.cornerRadius = 19
        menuButtonContainerView.clipsToBounds = true
        cameraButtonContainerView.clipsToBounds = true
        
        let menuTapToggleGesture = UITapGestureRecognizer(target: self, action: #selector(toggleMenuShowing))
        menuTapToggleView.addGestureRecognizer(menuTapToggleGesture)
        self.menuTapToggleGesture = menuTapToggleGesture
        
        let menuEdgeSwipeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(toggleMenuShowingSwiping))
        menuEdgeSwipeGesture.edges = [.left]
        edgeMenuSwipeView.addGestureRecognizer(menuEdgeSwipeGesture)
        self.menuEdgeSwipeGesture = menuEdgeSwipeGesture
        
        addSubViewConreoller(appContext.mainViewMenuViewNavigationController, in: menuView)
        
        previewCollectionView.dataSource = self
        previewCollectionView.delegate = self
        previewCollectionView.collectionViewLayout = previewLayout.getLayout()
        previewLayout.viewModel = previewViewModel
        previewCollectionView.register(UINib(nibName: String(describing: LMMainViewPreviewCell.self), bundle: nil), forCellWithReuseIdentifier: String(describing: LMMainViewPreviewCell.self))
        
        state = .root
        
        statusBarGradientView.colors = [ dynamicGradientColor, UIColor.systemBackground.withAlphaComponent(0.0)]
        statusBarGradientView.startPoint = CGPoint(x: 0.5, y: 1)
        statusBarGradientView.startPoint = CGPoint(x: 0.5, y: 0)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        statusBarGradientView.colors = [dynamicGradientColor, UIColor.systemBackground.withAlphaComponent(0.0)]
    }
    
    static func getInstance(appContext: LMAppContext) -> LMMainViewController {
        let mainViewController = LMMainViewController(nibName: String(describing: LMMainViewController.self), bundle: nil)
        mainViewController.appContext = appContext
        mainViewController.previewViewModel = LMMainViewPreviewViewModel(appContext: appContext)
        return mainViewController
    }
    
    func focusPreview(notes: [LMNote]) {
        previewViewModel.build(notes: notes)
        previewCollectionView.reloadData()
        previewCollectionView.performBatchUpdates(nil, completion: nil)
    }
    
    func selectedNote(note: LMNote) {
        state = .contentFullScreen
        if let index = previewViewModel.notes.firstIndex(of: note) {
            previewCollectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredVertically, animated: true)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        switch state {
        case .root:
            return .default
        case .contentFullScreen:
            return .lightContent
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }
    
    @IBAction func toggleCameraTapped(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "toggleCamerView"), object: nil)
    }
    
    @objc func toggleMenuShowing() {
        if self.state == .root {
            self.state = .contentFullScreen
        } else if self.state == .contentFullScreen {
            self.state = .root
        }
    }
    
    @objc func toggleMenuShowingSwiping(_ sender: UIScreenEdgePanGestureRecognizer) {
        switch sender.state {
        case .changed:
            let translationX = sender.translation(in: view).x
            let offsetX = min(0, -self.menuView.bounds.width + translationX)
            
            self.menuView.transform = CGAffineTransform(translationX: offsetX, y: 0)
            self.menuView.layer.shadowOpacity = 0.6 - Float((-offsetX * 0.6) / (self.menuView.bounds.width))
        case .ended:
            let translationX = sender.translation(in: view).x
            if translationX > (self.menuView.bounds.width) / 2 {
                self.state = .root
            } else {
                self.state = .contentFullScreen
            }
        case .cancelled:
            self.state = .contentFullScreen
        default:
            return
        }
    }
    
    @IBAction func toggleMenu(_ sender: Any) {
        self.state = .root
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

extension LMMainViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let number = previewViewModel.notes.count
        collectionView.isHidden = number == 0
        return number
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: LMMainViewPreviewCell.self), for: indexPath)
        if let cell = cell as? LMMainViewPreviewCell {
            cell.configure(note: previewViewModel.notes[indexPath.row], appContext: appContext)
        }
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
}
