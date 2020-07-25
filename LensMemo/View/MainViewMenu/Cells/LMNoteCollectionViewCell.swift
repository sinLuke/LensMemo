//
//  LMNoteCollectionViewCell.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-11.
//

import UIKit

class LMNoteCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var noteImage: UIImageView!
    var uuid: UUID?
    var note: LMNote?
    var thumbnail: Bool = false
    var appContext: LMAppContext?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        noteImage.contentMode = .scaleAspectFill
        noteImage.layer.borderColor = UIColor.separator.cgColor
        noteImage.layer.borderWidth = 1 / UIScreen.main.scale
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
        loadImage()
    }
    
    func loadImage(fromLocal: Bool = false) {
        if let note = self.note, let cashedImage = (appContext?.imageService.getImage(for: note, quality: .small, onlyFromLocal: fromLocal, completion: { (result) in
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
