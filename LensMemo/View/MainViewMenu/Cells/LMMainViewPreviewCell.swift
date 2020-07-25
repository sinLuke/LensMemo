//
//  LMMainViewPreviewCell.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-11.
//

import UIKit

class LMMainViewPreviewCell: UICollectionViewCell {
    
    @IBOutlet weak var noteImage: UIImageView!
    @IBOutlet weak var gradientView: UIGradientView!
    var gradientLayer = CAGradientLayer()
    var uuid: UUID?
    var note: LMNote?
    var thumbnail: Bool = false
    var appContext: LMAppContext?

    override func awakeFromNib() {
        super.awakeFromNib()
        noteImage.contentMode = .scaleAspectFill
        gradientView.colors = [UIColor.black.withAlphaComponent(0), UIColor.black.withAlphaComponent(0.8)]
        gradientView.startPoint = CGPoint(x: 0.5, y: 0)
        gradientView.endPoint = CGPoint(x: 0.5, y: 1)
        prepareForReuse()
        NotificationCenter.default.addObserver(self, selector: #selector(downloadFinished), name: .downloadFinished, object: nil)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        noteImage.image = nil
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
        loadImage()
    }
    
    func loadImage(fromLocal: Bool = false) {
        if let note = self.note, let cashedImage = (appContext?.imageService.getImage(for: note, quality: .large, onlyFromLocal: fromLocal, completion: { (result) in
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
