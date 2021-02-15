//
//  LMImagePreviewViewModel.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-11.
//

import UIKit

class LMImagePreviewViewModel: ViewModel {
    var notes: [LMNote] = []
    var filteringNotes: [LMNote] = []
    var filteredNotes: [LMNote] {
        if filteringNotes.isEmpty {
            return notes
        } else {
            return filteringNotes
        }
    }
    weak var appContext: LMAppContext?
    private var needReload = false
    init(appContext: LMAppContext) {
        self.appContext = appContext
    }

    func build(notes: [LMNote]) {
        if notes.isEmpty {
            let coverFetchedResultsController = appContext?.noteService.fetchedResultsController(noteBook: nil, sticker: nil, thatsOnCover: true)
            let loadedNotes = coverFetchedResultsController?.fetchedObjects
            self.notes = loadedNotes ?? []
            
        }
        if self.notes != notes {
            self.notes = notes
            needReload = true
        }
    }
    
    func filter(notes filterNotes: [LMNote]) {
        if self.filteringNotes != filterNotes {
            self.filteringNotes = filterNotes
            needReload = true
        }
        
    }
    
    func needReloadData() -> Bool {
        if needReload {
            needReload = false
            return true
        } else {
            return false
        }
    }
}
