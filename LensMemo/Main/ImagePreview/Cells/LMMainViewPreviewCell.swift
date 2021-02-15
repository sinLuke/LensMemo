//
//  LMMainViewPreviewCell.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-11.
//

import UIKit

class LMMainViewPreviewCell: UICollectionViewCell {
    
    @IBOutlet weak var noteImage: LMImageView!
    @IBOutlet weak var gradientView: UIGradientView!
    var gradientLayer = CAGradientLayer()
    var uuid: UUID?
    var note: LMNote?
    var thumbnail: Bool = false
    weak var appContext: LMAppContext?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        gradientView.colors = [UIColor.black.withAlphaComponent(0), UIColor.black.withAlphaComponent(0.8)]
        gradientView.startPoint = CGPoint(x: 0.5, y: 0)
        gradientView.endPoint = CGPoint(x: 0.5, y: 1)
        prepareForReuse()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        noteImage.prepareForReuse()
        self.note = nil
        self.thumbnail = false
        self.appContext = nil
        self.backgroundColor = .black
    }
    
    func configure(note: LMNote, thumbnail: Bool = false, appContext: LMAppContext) {
        guard let noteID = note.id else { return }
        self.uuid = noteID
        self.note = note
        self.thumbnail = thumbnail
        self.appContext = appContext
        gradientView.isHidden = note.isDocument
        self.noteImage.setImage(note: note, quality: thumbnail ? .small : .large, appContext: appContext)
    }
}
