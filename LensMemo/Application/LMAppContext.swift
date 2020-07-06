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
    
    lazy var mainViewMenuNoteListViewController: LMMainViewMenuNoteListViewController = {
        return LMMainViewMenuNoteListViewController.getInstance(appContext: self)
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
                } catch(let error) {
                    callBack(.failure(error))
                }
                
                appContext.noteBookService.appContext = appContext
                appContext.noteService.appContext = appContext
                appContext.stickerService.appContext = appContext
                
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
        mainViewMenuNoteListViewController.notebook = notebook
        if mainViewMenuNoteListViewController.isViewLoaded {
            mainViewMenuNoteListViewController.mainMenuNoteListDelegate = try? MainViewMenuNoteListTableViewDelegate(tableView: mainViewMenuNoteListViewController.tableView, appContext: self, notebook: notebook, thatsOnCover: false)
            mainViewMenuNoteListViewController.tableView.delegate = mainViewMenuNoteListViewController.mainMenuNoteListDelegate
            mainViewMenuNoteListViewController.tableView.dataSource = mainViewMenuNoteListViewController.mainMenuNoteListDelegate
        }
        
        if !mainViewMenuViewNavigationController.viewControllers.contains(mainViewMenuNoteListViewController) {
            mainViewMenuViewNavigationController.pushViewController(mainViewMenuNoteListViewController, animated: true)
        }
    }
}

extension LMAppContext {
    struct LMAppState {
        var selectedNotebook: LMNotebook? = nil
        var selectedNote: LMNote? = nil
        var selectedSticker: LMSticker? = nil
    }
}
