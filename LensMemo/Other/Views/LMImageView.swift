//
//  LMImageView.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-08-29.
//

import UIKit

class LMImageView: UIImageView {
    private var noteID: UUID?
    private var quality: LMImage.Quality?
    weak var appContext: LMAppContext?
    var compactColor: Int64 = 0
    
    func prepareForReuse() {
        noteID = nil
        quality = nil
        image = nil
        contentMode = .scaleAspectFill
    }
    
    func setImage(note: LMNote, quality: LMImage.Quality?, appContext: LMAppContext) {
        contentMode = .scaleAspectFill
        guard let noteID = note.id else { return }
        self.quality = quality
        self.appContext = appContext
        self.compactColor = note.compactColor
        if self.noteID != noteID {
            image = UIImage(color: UIColor(compactColor: self.compactColor))
            self.noteID = noteID
            updateImageIfNeeded()
        }
    }
    
    func updateImageIfNeeded() {
        guard let noteID = noteID, let imageService = appContext?.imageService else {
            prepareForReuse()
            return
        }
        
        // From Memory
        if let imageFromMemory = imageService.getImageFromMemory(for: noteID, quality: quality) {
            self.image = imageFromMemory
            return
        } else if let anyImageFromMemory = imageService.getImageFromMemory(for: noteID, quality: nil) {
            self.image = anyImageFromMemory
        }
        
        // From Disk
        if let imageFromMemory = imageService.getImageFromDisk(for: noteID, quality: self.quality) {
            if noteID == self.noteID {
                self.image = imageFromMemory
            }
            return
        } else if let anyImageFromMemory = imageService.getImageFromDisk(for: noteID, quality: nil) {
            if noteID == self.noteID {
                self.image = anyImageFromMemory
            }
        }
        
        DispatchQueue.global().async {
            // From Cloud
            imageService.getImageFromCloud(for: noteID, quality: self.quality ?? .small) { (result) in
                result.see { (image) in
                    main {
                        if noteID != self.noteID { return }
                        if let imageFromCloud = image {
                            self.image = imageFromCloud
                        } else {
                            self.image = UIImage(color: UIColor(compactColor: self.compactColor))
                        }
                    }
                } ifNot: { (error) in
                    if let lmError = error as? LMError {
                        switch lmError {
                        case LMError.iCloudImageError:
                            main {
                                if noteID != self.noteID { return }
                                self.image = UIImage(color: UIColor(compactColor: self.compactColor))
                            }
                        default:
                            fatalError(error.localizedDescription)
                        }
                    } else {
                        fatalError(error.localizedDescription)
                    }
                }
            }
        }
    }
}
