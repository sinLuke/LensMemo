//
//  LMNoteEnclosure.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-08-25.
//

import UIKit

class LMNoteEnclosure: NSObject, NSItemProviderWriting {
    static var writableTypeIdentifiersForItemProvider: [String] = ["lensememo.note", "public.jpeg", "public.image"]
    weak var note: LMNote?
    weak var appContext: LMAppContext?
    
    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        let progress = Progress(totalUnitCount: 1)
        if typeIdentifier == "lensememo.note" {
            completionHandler((note?.id?.uuidString ?? "unknown").data(using: .utf8), nil)
            progress.completedUnitCount = 1
        } else if typeIdentifier == "public.jpeg" || typeIdentifier == "public.image" {
            if let note = self.note, let noteID = note.id, let appContext = self.appContext {
                appContext.imageService.getImages(for: [noteID]) { (results) in
                    main {
                        results.first?.see { (image) in
                            progress.completedUnitCount = 1
                            completionHandler(image.jpegData(compressionQuality: CGFloat(LMUserDefaults.jpegCompressionQuality)), nil)
                        } ifNot: { (error) in
                            progress.cancel()
                            completionHandler(nil, error)
                        }
                    }
                }
            }
        } else {
            progress.cancel()
            completionHandler(nil, NSError())
        }
        return progress
    }
    
    
    init(note: LMNote, appContext: LMAppContext) {
        self.note = note
        self.appContext = appContext
    }
}
