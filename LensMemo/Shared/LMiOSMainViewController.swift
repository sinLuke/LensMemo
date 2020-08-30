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
    @IBOutlet weak var imageDetailSnackbar: UIView!
    @IBOutlet weak var snackbarShadowView: UIView!
    @IBOutlet weak var snackbarImage: UIImageView!
    @IBOutlet weak var snackbarTitle: UILabel!
    @IBOutlet weak var sncakbarMessage: UILabel!
    
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
    
    var isSnackbarHidden: Bool = true {
        didSet {
            configureSnackbar()
            appContext.mainViewMenuViewNavigationController.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: isSnackbarHidden ? 0 : 120, right: 0)
            UIView.animate(withDuration: 0.3) {
                self.imageDetailSnackbar.transform = self.isSnackbarHidden ? CGAffineTransform(translationX: 0, y: 200) : .identity
            }
        }
    }
    
    var state: State = .root {
        didSet {
            guard appContext.mainViewMenuViewNavigationController.topViewController?.isViewLoaded == true else { return }
            print("state == .root\(state == .root)")
            switch state{
            case .root:
                isSnackbarHidden = false
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
        
        setupSnackbar()
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
    
    func selectedNote(note: LMNote) {
        if let index = previewViewModel.notes.firstIndex(of: note), state == .root {
            previewDisplayView.scrollTo(item: index)
            state = .contentFullScreen
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
        if let selectedNote = appContext.state.selectedNote, let selectedNotebook = appContext.state.selectedNotebook, selectedNote.notebook == selectedNotebook, state == .root {
            isSnackbarHidden = false
        }
        
        if let selectedNote = appContext.state.selectedNote, let selectedSticker = appContext.state.selectedSticker, selectedNote.stickers?.contains(selectedSticker) == true, state == .root {
            isSnackbarHidden = false
        }
    }
    
    @IBAction func toggleMenu(_ sender: Any) {
        self.state = .root
    }
}

extension LMiOSMainViewController { // snackbar
    func setupSnackbar() {
        snackbarShadowView.layer.shadowColor = UIColor.black.cgColor
        snackbarShadowView.layer.shadowRadius = 16
        snackbarShadowView.layer.shadowOpacity = 0.6
        imageDetailSnackbar.layer.cornerRadius = 20
        
        imageDetailSnackbar.transform = CGAffineTransform(translationX: 0, y: 200)
        
        snackbarGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(snackBarPanSelector))
        imageDetailSnackbar.addGestureRecognizer(snackbarGestureRecognizer!)
    }
    
    func configureSnackbar() {
        if let note = appContext.state.selectedNote {
            snackbarImage.image = appContext.imageService.getImage(for: note, quality: .small, onlyFromLocal: false, completion: { [weak self] (image) in
                if note == self?.appContext.state.selectedNote {
                    self?.snackbarImage.image = try? image.get()
                }
            })
            
            let dataFomatter = NoteDateFomatter()
            if let createDate = note.created {
                snackbarTitle.text = dataFomatter.string(from: createDate)
            }
            
            if note.message == nil || note.message == "" {
                if let createDate = note.created {
                    sncakbarMessage.text = "This note was created \(dataFomatter.string(from: createDate))"
                } else {
                    sncakbarMessage.text = "Untitled Note"
                }
            } else {
                sncakbarMessage.text = note.message
            }
        }
    }
    
    func hideSnackbarIfCan() {
        isSnackbarHidden = true
    }
    
    @objc func snackBarPanSelector(_ sender: UIPanGestureRecognizer) {
        func signedSqrt(_ value: CGFloat) -> CGFloat {
            let sqrtValue = sqrt(Double(abs(value)))
            return CGFloat(sign(Double(value)) * sqrtValue)
        }
        switch sender.state {
        case .changed:
            var translation = CGPoint(x: signedSqrt(sender.translation(in: view).x), y: signedSqrt(sender.translation(in: view).y))
            if sender.translation(in: view).y > 0 {
                translation.y = sender.translation(in: view).y
            }
            self.imageDetailSnackbar.transform = CGAffineTransform(translationX: translation.x, y: translation.y)
        case .ended:
            let translation = sender.translation(in: view)
            if translation.y > 0 {
                isSnackbarHidden = true
            } else {
                isSnackbarHidden = false
            }
        case .cancelled:
            isSnackbarHidden = false
        case .failed:
            isSnackbarHidden = false
        default:
            return
        }
    }
    
    @IBAction func snackbarOnTab(_ sender: Any) {
        let imageDetailViewController = LMImageDetailViewController.getInstance(appContext: appContext)
        imageDetailViewController.loadView()
        imageDetailViewController.viewDidLoad()
        imageDetailViewController.configure(note: appContext.state.selectedNote)
        present(imageDetailViewController, animated: true, completion: nil)
    }
    
    @IBAction func snackbarImageOnTab(_ sender: Any) {
        if appContext.state.selectedNote?.notebook == appContext.state.selectedNotebook {
            guard let note = appContext.state.selectedNote else { return }
            selectedNote(note: note)
        }
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

extension LMiOSMainViewController: LMDisplayViewDataSource {
    func numberOfImages() -> Int {
        return previewViewModel.notes.count
    }
    
    func displayView(_ displayView: LMDisplayView, sizeOfImageAt index: Int) -> CGSize {
        return CGSize(width: CGFloat(previewViewModel.notes[index].imageWidth), height: CGFloat(previewViewModel.notes[index].imageHeight))
    }
    
    func displayView(_ displayView: LMDisplayView, imageAt index: Int, quality: LMImage.Quality?) -> UIImage? {
        let lastValidUpdate = lastUpdate
        if let image = appContext.imageService.getImage(for: previewViewModel.notes[index], quality: quality ?? .original, onlyFromLocal: false, completion: { (result) in
            result.see(ifSuccess: { (_) in
                DispatchQueue.main.async {
                    if lastValidUpdate == self.lastUpdate {
                        displayView.loadImage(at: index)
                    }
                }
            }) { (_) in
                return
            }
        }) {
            return image
        } else {
            return nil
        }
    }
    
    func displayView(_ displayView: LMDisplayView, compactColorOfImageAt index: Int) -> UIColor {
        return UIColor(compactColor: previewViewModel.notes[index].compactColor)
    }
}

extension LMiOSMainViewController: LMDisplayViewDelegate {
    func shouldUseTimmer() -> Bool {
        state == .contentFullScreen
    }
    
    func displayViewDidScrollTo(_ index: Int) {
        if appContext.state.selectedNote != previewViewModel.notes[index] {
            appContext.selectedNote(note: previewViewModel.notes[index])
        }
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
        previewViewModel.notes[index].lastViewed = Date()
        try? appContext.storage.saveContext()
    }
    
    func displayViewShowNoteDetail(_ index: Int) {
        let imageDetailViewController = LMImageDetailViewController.getInstance(appContext: appContext)
        imageDetailViewController.loadView()
        imageDetailViewController.viewDidLoad()
        imageDetailViewController.configure(note: previewViewModel.notes[index])
        present(imageDetailViewController, animated: true, completion: nil)
    }
}

#endif
