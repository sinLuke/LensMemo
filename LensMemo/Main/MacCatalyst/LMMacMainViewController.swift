//
//  LMMacMainViewController.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-26.
//

#if targetEnvironment(macCatalyst)

import Cocoa
import UIKit

class LMMacMainViewController: UISplitViewController {
    
    weak var appContext: LMAppContext!
    
    var isInternetWorking: Bool = true
    
    var previewLayout = LMMainViewPreviewLayout()
    var menuEdgeSwipeGesture: UIScreenEdgePanGestureRecognizer?
    var previewViewModel: LMImagePreviewViewModel!
    
    var lastUpdate = Date()
    
    var dynamicGradientColor = UIColor(dynamicProvider: { (trait) -> UIColor in
        if trait.userInterfaceStyle == .dark {
            return .clear
        } else {
            return UIColor.white.withAlphaComponent(0.5)
        }
    })
    
    override func didReceiveMemoryWarning() {
        print("here")
    }
    
    func hideSnackbarIfCan() {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = [appContext.mainViewMenuViewController, appContext.mainDetailViewController]
        delegate = self
        primaryBackgroundStyle = .sidebar
        preferredDisplayMode = .allVisible
        previewLayout.viewModel = previewViewModel
        
        minimumPrimaryColumnWidth = 180
        maximumPrimaryColumnWidth = 1000
        preferredPrimaryColumnWidthFraction = 0.15
    }
    
    static func getInstance(appContext: LMAppContext) -> LMMacMainViewController {
        let mainViewController = LMMacMainViewController()
        mainViewController.appContext = appContext
        mainViewController.previewViewModel = LMImagePreviewViewModel(appContext: appContext)
        return mainViewController
    }
    
    func focusPreview(notes: [LMNote]) {
        lastUpdate = Date()
        appContext.mainDetailViewController.focusPreview(notes: notes)
    }
    
    func selectedNote(note: LMNote) {
        appContext.mainDetailViewController.selectedNote(note: note)
    }
    
    func appStateDidSet() {
        return
    }
}

extension LMMacMainViewController {
    enum State {
        case root
        case contentFullScreen
    }
}

extension LMMacMainViewController: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
}

#endif
