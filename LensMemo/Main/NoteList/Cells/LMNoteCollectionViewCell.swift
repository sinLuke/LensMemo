//
//  LMNoteCollectionViewCell.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-11.
//

import UIKit

class LMNoteCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var noteImage: UIImageView!
    @IBOutlet weak var boarderView: UIView!
    var uuid: UUID?
    var note: LMNote?
    var thumbnail: Bool = false
    weak var appContext: LMAppContext?
    var lastSelected = false
    
    func styleSelected() {
        let isSmallIcon = frame.width == frame.height
        let isSelectedNote = isSmallIcon && appContext?.state.selectedNote == note && note != nil
        if lastSelected != isSelectedNote {
            UIView.animate(withDuration: isSelectedNote ? 0.3 : 0.0) {
                self.layer.shadowColor = isSelectedNote ? UIColor.black.cgColor : UIColor.clear.cgColor
                self.layer.shadowRadius = isSelectedNote ? 16 : 0
                self.layer.shadowOpacity = isSelectedNote ? 0.8 : 0
                self.layer.zPosition = isSelectedNote ? 1000 : 0
                self.noteImage.layer.borderColor = isSelectedNote ? UIColor.white.cgColor : UIColor.separator.cgColor
                self.noteImage.layer.borderWidth = isSelectedNote ? 3 : 1 / UIScreen.adjustedScale
            }
        }
        
        self.lastSelected = isSelectedNote
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        noteImage.contentMode = .scaleAspectFill
        noteImage.layer.borderColor = UIColor.separator.cgColor
        noteImage.layer.borderWidth = 1 / UIScreen.adjustedScale
        prepareForReuse()
        NotificationCenter.default.addObserver(self, selector: #selector(downloadFinished), name: .downloadFinished, object: nil)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        noteImage.image = nil
        self.note = nil
        self.thumbnail = false
        self.appContext = nil
        self.backgroundColor = .systemFill
    }
    
    func configure(note: LMNote, thumbnail: Bool = false, appContext: LMAppContext) {
        guard let noteID = note.id else { return }
        self.note = note
        self.thumbnail = thumbnail
        self.appContext = appContext
        self.uuid = noteID
        self.backgroundColor = UIColor(compactColor: note.compactColor) 
        styleSelected()
        loadImage()
    }
    
    func loadImage(fromLocal: Bool = false) {
        guard let note = note else { return }
        
        if let cashedImage = (appContext?.imageService.getImage(for: note, quality: .small, onlyFromLocal: fromLocal, completion: { (result) in
            result.see(ifSuccess: { (image) in
                if self.uuid == note.id {
                    self.noteImage.image = image
                }
            }) { (_) in
                return
            }
        })) {
            self.noteImage.image = cashedImage
        }
    }
    
    @objc func downloadFinished() {
        loadImage(fromLocal: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
