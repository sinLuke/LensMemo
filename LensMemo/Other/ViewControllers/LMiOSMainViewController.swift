//
//  LMiOSMainViewController.swift
//  LensMemo-iOS
//
//  Created by Luke Yin on 2020-07-01.
//

#if !targetEnvironment(macCatalyst)

import UIKit
import CoreData

class LMiOSMainViewController: LMViewController {
    @IBOutlet weak var previewDisplayView: LMDisplayView!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var edgeMenuSwipeView: UIView!
    @IBOutlet weak var menuButtonContainerView: UIVisualEffectView!
    @IBOutlet weak var cameraButtonContainerView: UIVisualEffectView!
    @IBOutlet weak var statusBarGradientView: UIGradientView!
    
    @IBOutlet weak var networkIndicator: UIView!
    @IBOutlet weak var networkIndicatorLabel: UILabel!
    
    var isInternetWorking: Bool = true {
        didSet {
            if isViewLoaded {
                networkIndicator.isHidden = isInternetWorking
                networkIndicatorLabel.text = l("No internet")
            }
        }
    }
    
    var previewLayout = LMMainViewPreviewLayout()
    var menuEdgeSwipeGesture: UIScreenEdgePanGestureRecognizer?
    var previewViewModel: LMImagePreviewViewModel!
    var snackbarGestureRecognizer: UIPanGestureRecognizer?
    
    var lastUpdate = Date()
    
    var dynamicGradientColor = UIColor(dynamicProvider: { (trait) -> UIColor in
        if trait.userInterfaceStyle == .dark {
            return .clear
        } else {
            return UIColor.white.withAlphaComponent(0.5)
        }
    })
    
    var state: State = .root {
        didSet {
            guard appContext.mainViewMenuViewNavigationController.topViewController?.isViewLoaded == true else { return }
            print("state == .root\(state == .root)")
            switch state{
            case .root:
                edgeMenuSwipeView.isHidden = true
                self.statusBarGradientView.alpha = 0.0
                previewDisplayView.resetZoomLevel()
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                    self.menuView.transform = .identity
                    self.menuView.layer.shadowOpacity = 0.6
                    self.statusBarGradientView.alpha = 1.0
                    self.setNeedsStatusBarAppearanceUpdate()
                })
                appContext.mainViewMenuViewNavigationController.topViewController?.viewWillAppear(true)
            case .contentFullScreen:
                edgeMenuSwipeView.isHidden = false
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
        
        networkIndicator.isHidden = isInternetWorking
        networkIndicatorLabel.text = l("No internet")
        
        previewDisplayView.configure(dataSource: self, delegate: self)
        previewDisplayView.appContext = appContext
        
        menuView.layer.shadowColor = UIColor.black.cgColor
        menuView.layer.shadowOffset = CGSize(width: 0, height: 0)
        menuView.layer.shadowRadius = 16
        menuView.layer.shadowOpacity = 0.6
        
        menuButtonContainerView.layer.cornerRadius = 19
        cameraButtonContainerView.layer.cornerRadius = 19
        menuButtonContainerView.clipsToBounds = true
        cameraButtonContainerView.clipsToBounds = true
        
        let menuEdgeSwipeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(toggleMenuShowingSwiping))
        menuEdgeSwipeGesture.edges = [.left]
        edgeMenuSwipeView.addGestureRecognizer(menuEdgeSwipeGesture)
        self.menuEdgeSwipeGesture = menuEdgeSwipeGesture
        
        addSubViewConreoller(appContext.mainViewMenuViewNavigationController, in: menuView)
        
        previewLayout.viewModel = previewViewModel
        
        state = .root
        
        statusBarGradientView.colors = [ dynamicGradientColor, UIColor.systemBackground.withAlphaComponent(0.0)]
        statusBarGradientView.startPoint = CGPoint(x: 0.5, y: 1)
        statusBarGradientView.startPoint = CGPoint(x: 0.5, y: 0)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        statusBarGradientView.colors = [dynamicGradientColor, UIColor.systemBackground.withAlphaComponent(0.0)]
    }
    
    static func getInstance(appContext: LMAppContext) -> LMiOSMainViewController {
        let mainViewController = LMiOSMainViewController(nibName: String(describing: LMiOSMainViewController.self), bundle: nil)
        mainViewController.appContext = appContext
        mainViewController.previewViewModel = LMImagePreviewViewModel(appContext: appContext)
        return mainViewController
    }
    
    func focusPreview(notes: [LMNote]) {
        lastUpdate = Date()
        previewViewModel.build(notes: notes)
        previewDisplayView.reloadData()
        previewDisplayView.resetZoomLevel(animated: false)
    }
    
    func focusFilterPreview(notes: [LMNote]) {
        lastUpdate = Date()
        previewViewModel.filter(notes: notes)
        previewDisplayView.reloadData()
        previewDisplayView.resetZoomLevel(animated: false)
    }
    
    func selectedNotes(notes: [LMNote], shouldHideMenuView: Bool) {
        if let theNote = notes.last, let index = previewViewModel.notes.firstIndex(of: theNote), state == .root {
            previewDisplayView.scrollTo(item: index)
            if shouldHideMenuView {
                state = .contentFullScreen
            }
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
    
    override func appStateDidSet() {
        if let selectedNote = appContext.state.selectedNotes.last, let selectedNotebook = appContext.state.selectedNotebook, selectedNote.notebook == selectedNotebook, state == .root {
        }
        
        if let selectedNote = appContext.state.selectedNotes.last, let selectedSticker = appContext.state.selectedSticker, selectedNote.stickers?.contains(selectedSticker) == true, state == .root {
        }
    }
    
    @IBAction func toggleMenu(_ sender: Any) {
        self.state = .root
    }
}

extension LMiOSMainViewController {
    enum State {
        case root
        case contentFullScreen
    }
}

extension LMiOSMainViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let number = previewViewModel.filteredNotes.count
        collectionView.isHidden = number == 0
        return number
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: LMMainViewPreviewCell.self), for: indexPath)
        if let cell = cell as? LMMainViewPreviewCell {
            cell.configure(note: previewViewModel.filteredNotes[indexPath.row], appContext: appContext)
        }
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
}

extension LMiOSMainViewController: LMDisplayViewDataSource {
    func numberOfImages() -> Int {
        return previewViewModel.filteredNotes.count
    }
    
    func displayView(_ displayView: LMDisplayView, sizeOfImageAt index: Int) -> CGSize {
        return CGSize(width: CGFloat(previewViewModel.filteredNotes[index].imageWidth), height: CGFloat(previewViewModel.filteredNotes[index].imageHeight))
    }
    
    func displayView(_ displayView: LMDisplayView, noteAt index: Int) -> LMNote? {
        return previewViewModel.filteredNotes[index]
    }
    
    func displayView(_ displayView: LMDisplayView, compactColorOfImageAt index: Int) -> UIColor {
        return UIColor(compactColor: previewViewModel.filteredNotes[index].compactColor)
    }
    
    func needReloadData() -> Bool {
        previewViewModel.needReloadData()
    }
}

extension LMiOSMainViewController: LMDisplayViewDelegate {
    func shouldUseTimmer() -> Bool {
        state == .contentFullScreen
    }
    
    func displayViewDidScrollTo(_ index: Int) {

    }
    
    func displayViewDidRecievedTap(_ index: Int) {
        if self.state != .contentFullScreen {
            self.state = .contentFullScreen
        } else {
            self.state = .root
        }
    }
    
    func displayViewDidRecievedUserInteractive() {
        if self.state != .contentFullScreen {
            self.state = .contentFullScreen
        }
    }
    
    func displayViewDidFocusOnNote(_ index: Int) {
        previewViewModel.filteredNotes[index].lastViewed = Date()
        try? appContext.storage.saveContext()
    }
    
    func displayViewShowNoteDetail(_ index: Int) {
        let imageDetailViewController = LMImageDetailViewController.getInstance(appContext: appContext)
        imageDetailViewController.loadView()
        imageDetailViewController.viewDidLoad()
        imageDetailViewController.configure(note: previewViewModel.filteredNotes[index])
        present(imageDetailViewController, animated: true, completion: nil)
    }
}

#endif
