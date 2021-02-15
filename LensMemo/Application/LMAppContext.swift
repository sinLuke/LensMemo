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
    
    var draggingNote: LMNote?
    
    var state: LMAppState = LMAppState()
    
    // MARK: - Main View Menu
    lazy var mainViewMenuViewController: LMMainViewMenuViewController = {
        return LMMainViewMenuViewController.getInstance(appContext: self)
    }()

    // MARK: - Main Views
    
    #if targetEnvironment(macCatalyst)
    
    lazy var imageDetailViewController: LMImageDetailViewController = {
        return LMImageDetailViewController.getInstance(appContext: self)
    }()
    
    lazy var mainViewController: LMMacMainViewController = {
        return LMMacMainViewController.getInstance(appContext: self)
    }()
    
    lazy var mainDetailViewController: LMMacMainDetailViewController = {
        return LMMacMainDetailViewController.getInstance(appContext: self)
    }()
    
    lazy var mainViewMenuNoteListViewController: LMNoteListViewController = {
        LMNoteListViewController.getInstance(appContext: self, notebook: nil, thatsOnCover: false)
    }()
    
    #else
    
    lazy var mainViewMenuViewNavigationController: MainViewMenuNavigationController = {
        return MainViewMenuNavigationController(appContext: self, rootViewController: mainViewMenuViewController)
    }()
    
    lazy var mainViewController: LMiOSMainViewController = {
        return LMiOSMainViewController.getInstance(appContext: self)
    }()
    
    lazy var cameraViewController: LMCameraViewController = {
        return LMCameraViewController.getInstance(appContext: self)
    }()
    
    #endif
    
    // MARK: - Camera Views
    
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
                LMInternetService.shared.appContext = appContext
                
                appContext.activityService.addActivity()
                appContext.state.appContext = appContext
                
                callBack(.success(appContext))
            case let .failure(error):
                callBack(.failure(error))
            }
        }
    }
    
    private init() {}
    
    func appStateDidSet() {
        #if targetEnvironment(macCatalyst)
        mainDetailViewController.appStateDidSet()
        mainViewMenuNoteListViewController.appStateDidSet()
        imageDetailViewController.appStateDidSet()
        #else
        mainViewMenuViewNavigationController.appStateDidSet()
        cameraViewController.appStateDidSet()
        #endif
        mainViewMenuViewController.appStateDidSet()
        mainViewController.appStateDidSet()
    }
    
    func navigateTo(sticker: LMSticker) {
        #if targetEnvironment(macCatalyst)
        mainViewMenuNoteListViewController.update(notebook: nil, sticker: sticker, thatsOnCover: false)
        #else
        if !mainViewMenuViewNavigationController.viewControllers.contains(where: { (viewController) -> Bool in
            viewController is LMNoteListViewController
        }) {
            let mainViewMenuNoteListViewController = LMNoteListViewController.getInstance(appContext: self, sticker: sticker)
            mainViewMenuViewNavigationController.pushViewController(mainViewMenuNoteListViewController, animated: true)
        } else {
            mainViewMenuViewNavigationController.viewControllers.forEach { viewController in
                if let mainViewMenuNoteListViewController = viewController as? LMNoteListViewController {
                    mainViewMenuNoteListViewController.update(notebook: nil, sticker: sticker, thatsOnCover: false)
                }
            }
        }
        #endif
    }
    
    func navigateTo(notebook: LMNotebook) {
        
        #if targetEnvironment(macCatalyst)
        mainViewMenuNoteListViewController.update(notebook: notebook, sticker: nil, thatsOnCover: false)
        #else
        if !mainViewMenuViewNavigationController.viewControllers.contains(where: { (viewController) -> Bool in
            viewController is LMNoteListViewController
        }) {
            let mainViewMenuNoteListViewController = LMNoteListViewController.getInstance(appContext: self, notebook: notebook, thatsOnCover: false)
            mainViewMenuViewNavigationController.pushViewController(mainViewMenuNoteListViewController, animated: true)
        } else {
            mainViewMenuViewNavigationController.viewControllers.forEach { viewController in
                if let mainViewMenuNoteListViewController = viewController as? LMNoteListViewController {
                    mainViewMenuNoteListViewController.update(notebook: notebook, sticker: nil, thatsOnCover: false)
                }
            }
        }
        #endif
    }
    
    func forcusOn(notes: [LMNote]) {
        main {
            self.mainViewController.focusPreview(notes: notes)
        }
    }
    
    func selectedNotes(notes: [LMNote], shouldHideMenuView: Bool = true) {
        main {
            self.state.selectedNotes = notes
            self.mainViewController.focusFilterPreview(notes: [])
            self.mainViewController.selectedNotes(notes: notes, shouldHideMenuView: shouldHideMenuView)
        }
    }
    
    func toggleSelectNote(note: LMNote, shouldHideMenuView: Bool = true) {
        main {
            self.state.toggleSelectNote(note)
            if self.state.selectedNotes.count > 1 {
                self.mainViewController.focusFilterPreview(notes: self.state.selectedNotes)
            } else {
                self.mainViewController.focusFilterPreview(notes: [])
                if let lastSelectedNotes = self.state.selectedNotes.last {
                    self.mainViewController.selectedNotes(notes: [lastSelectedNotes], shouldHideMenuView: shouldHideMenuView)
                }
            }
        }
    }
    
    func addSelectNote(note: LMNote, shouldHideMenuView: Bool = true) {
        main {
            self.state.addSelectNote(note)
            if self.state.selectedNotes.count > 1 {
                self.mainViewController.focusFilterPreview(notes: self.state.selectedNotes)
            } else {
                self.mainViewController.focusFilterPreview(notes: [])
                if let lastSelectedNotes = self.state.selectedNotes.last {
                    self.mainViewController.selectedNotes(notes: [lastSelectedNotes], shouldHideMenuView: shouldHideMenuView)
                }
            }
        }
    }
    
    func removeSelectNote(note: LMNote, shouldHideMenuView: Bool = true) {
        main {
            self.state.removeSelectNote(note)
            if self.state.selectedNotes.count > 1 {
                self.mainViewController.focusFilterPreview(notes: self.state.selectedNotes)
            } else {
                self.mainViewController.focusFilterPreview(notes: [])
                if let lastSelectedNotes = self.state.selectedNotes.last {
                    self.mainViewController.selectedNotes(notes: [lastSelectedNotes], shouldHideMenuView: shouldHideMenuView)
                }
            }
        }
    }
}

extension LMAppContext {
    class LMAppState {
        weak var appContext: LMAppContext?
        var selectedNotebook: LMNotebook? = nil {
            didSet {
                if selectedNotebook != nil {
                    selectedSticker = nil
                }
            }
        }
        var selectedNotes: [LMNote] = []
        var selectedSticker: LMSticker? = nil {
            didSet {
                if selectedSticker != nil {
                    selectedNotebook = nil
                }
            }
        }
        var applyingSticker: LMSticker? = nil
        
        func resetSelectNote(_ notes: [LMNote]) {
            selectedNotes = notes
            appContext?.appStateDidSet()
        }
        
        func addSelectNote(_ note: LMNote) {
            if !selectedNotes.contains(note) {
                selectedNotes.append(note)
            }
        }
        
        func removeSelectNote(_ note: LMNote) {
            if selectedNotes.contains(note) {
                selectedNotes.removeAll {
                    note.id == $0.id
                }
            }
        }
        
        func toggleSelectNote(_ note: LMNote) {
            if selectedNotes.contains(note) {
                selectedNotes.removeAll {
                    note.id == $0.id
                }
            } else {
                selectedNotes.append(note)
            }
        }
    }
}
