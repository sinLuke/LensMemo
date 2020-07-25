//
//  LMAppContext.swift
//  LensMemo-iOS
//
//  Created by Luke Yin on 2020-07-01.
//

import UIKit

class LMAppContext {
    var orientation: UIDeviceOrientation = .unknown
    var storage: LMPersistentStorageService!
    var noteBookService: LMNotebookDataService!
    var noteService: LMNoteDataService!
    var justShotService: LMJustShotDataService!
    var stickerService: LMStickerDataService!
    var activityService: LMActivityDataService!
    var imageService: LMImageService!
    
    var state: LMAppState = LMAppState() {
        didSet {
            appStateDidSet()
        }
    }
    
    // MARK: - Main View Menu
    lazy var mainViewMenuViewNavigationController: MainViewMenuNavigationController = {
        return MainViewMenuNavigationController(appContext: self, rootViewController: mainViewMenuViewController)
    }()
    
    lazy var mainViewMenuViewController: LMMainViewMenuViewController = {
        return LMMainViewMenuViewController.getInstance(appContext: self)
    }()

    // MARK: - Main Views
    
    lazy var mainViewController: LMMainViewController = {
        return LMMainViewController.getInstance(appContext: self)
    }()
    
    // MARK: - Camera Views
    
    lazy var cameraViewController: LMCameraViewController = {
        return LMCameraViewController.getInstance(appContext: self)
    }()
    
    static func getInstance(callBack: @escaping (Result<LMAppContext, Error>) -> ()) throws {
        LMPersistentStorageService.getInstance { (result) in
            switch result {
            case let .success(storage):
                let appContext = LMAppContext()
                appContext.storage = storage
                do {
                    try appContext.noteBookService = LMNotebookDataService(persistentService: storage)
                    appContext.justShotService = LMJustShotDataService()
                    try appContext.stickerService = LMStickerDataService(persistentService: storage)
                    try appContext.activityService = LMActivityDataService(persistentService: storage)
                    try appContext.noteService = LMNoteDataService(persistentService: storage)
                    try appContext.imageService = LMImageService(persistentService: storage)
                } catch(let error) {
                    callBack(.failure(error))
                }
                
                appContext.noteBookService.appContext = appContext
                appContext.noteService.appContext = appContext
                appContext.stickerService.appContext = appContext
                LMDownloadService.shared.appContext = appContext
                callBack(.success(appContext))
            case let .failure(error):
                callBack(.failure(error))
            }
        }
    }
    
    private init() {}
    
    func appStateDidSet() {
        mainViewMenuViewNavigationController.appStateDidSet()
        mainViewMenuViewController.appStateDidSet()
        mainViewController.appStateDidSet()
        cameraViewController.appStateDidSet()
    }
    
    func navigateTo(notebook: LMNotebook) {
        guard let mainViewMenuNoteListViewController = LMMainViewMenuNoteListViewController.getInstance(appContext: self, notebook: notebook, thatsOnCover: false) else {
            return
        }
        if !mainViewMenuViewNavigationController.viewControllers.contains(where: { (viewController) -> Bool in
            viewController is LMMainViewMenuNoteListViewController
        }) {
            mainViewMenuViewNavigationController.pushViewController(mainViewMenuNoteListViewController, animated: true)
        } else {
            mainViewMenuViewNavigationController.popToRootViewController(animated: false)
            mainViewMenuViewNavigationController.pushViewController(mainViewMenuNoteListViewController, animated: false)
        }
    }
    
    func forcusOn(notes: [LMNote]) {
        mainViewController.focusPreview(notes: notes)
    }
    
    func selectedNote(note: LMNote) {
        mainViewController.selectedNote(note: note)
    }
}

extension LMAppContext {
    struct LMAppState {
        var selectedNotebook: LMNotebook? = nil
        var selectedNote: LMNote? = nil
        var selectedSticker: LMSticker? = nil
    }
}
