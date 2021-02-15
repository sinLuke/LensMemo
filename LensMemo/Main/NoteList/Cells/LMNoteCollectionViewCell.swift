//
//  LMNoteCollectionViewCell.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-11.
//

import UIKit

class LMNoteCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var noteImage: LMImageView!
    @IBOutlet weak var checkImageView: UIImageView!
    @IBOutlet weak var checkBoarder: UIImageView!
    var uuid: UUID?
    var note: LMNote?
    weak var appContext: LMAppContext?
    
    var isEditing: Bool = false
    
    func styleSelected() {
        let isSelectedNote: Bool
        if let theNote = note {
            isSelectedNote = appContext?.state.selectedNotes.contains(theNote) == true
        } else {
            isSelectedNote = false
        }
        
        checkImageView.isHidden = !(isSelectedNote && isEditing)
        checkBoarder.isHidden = !(isSelectedNote && isEditing)
        noteImage.alpha = (isSelectedNote && isEditing) ? 0.5 : 1.0
    }
    
    func mockSelectedEffect() {
        if noteImage.alpha != 1.0 {
            noteImage.alpha = 1.0
        } else {
            noteImage.alpha = 0.5
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        prepareForReuse()
        noteImage.contentMode = .scaleAspectFill
        noteImage.layer.borderColor = UIColor.separator.cgColor
        noteImage.layer.borderWidth = 1 / UIScreen.adjustedScale
        prepareForReuse()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        noteImage.prepareForReuse()
        self.note = nil
        self.appContext = nil
        self.backgroundColor = .systemBackground
    }
    
    func configure(note: LMNote, isEditing: Bool, appContext: LMAppContext) {
        guard let noteID = note.id else { return }
        self.note = note
        self.appContext = appContext
        self.uuid = noteID
        self.backgroundColor = .systemBackground
        
        self.isEditing = isEditing
        
        styleSelected()
        noteImage.setImage(note: note, quality: .small, appContext: appContext)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isEditing {
            mockSelectedEffect()
        }
        super.touchesBegan(touches, with: event)
    }
}
