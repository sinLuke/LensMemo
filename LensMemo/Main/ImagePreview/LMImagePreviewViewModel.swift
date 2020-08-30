//
//  LMImagePreviewViewModel.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-11.
//

import UIKit

class LMImagePreviewViewModel: ViewModel {
    var notes: [LMNote] = []
    weak var appContext: LMAppContext?
    init(appContext: LMAppContext) {
        self.appContext = appContext
    }

    func build(notes: [LMNote]) {
        if notes.isEmpty {
            let coverFetchedResultsController = appContext?.noteService.fetchedResultsController(noteBook: nil, sticker: nil, thatsOnCover: true)
            let loadedNotes = coverFetchedResultsController?.fetchedObjects
            self.notes = loadedNotes ?? []
        }
        self.notes = notes
    }
}
