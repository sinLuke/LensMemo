//
//  LMAppContext.swift
//  LensMemo-iOS
//
//  Created by Luke Yin on 2020-07-01.
//

import UIKit

class LMAppContext {
    var storage: LMPersistentStorageService
    var noteBookService: LMNotebookDataService
    var justShotService: LMJustShotDataService
    var stickerService: LMStickerDataService
    var activityService: LMActivityDataService
    
    init() throws {
        storage = LMPersistentStorageService()
        try noteBookService = LMNotebookDataService(persistentService: storage)
        justShotService = LMJustShotDataService()
        try stickerService = LMStickerDataService(persistentService: storage)
        try activityService = LMActivityDataService(persistentService: storage)
    }
}
