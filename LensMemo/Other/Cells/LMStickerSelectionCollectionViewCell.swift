//
//  LMStickerSelectionCollectionViewCell.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-08-23.
//

import UIKit

class LMStickerSelectionCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var selectionView: UIView!
    @IBOutlet weak var stickerLabel: UILabel!
    
    var note: LMNote?
    var sticker: LMSticker?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionView.backgroundColor = .clear
        
        let hoverGestureRecognizer = UIHoverGestureRecognizer(target: self, action: #selector(onHover))
        self.addGestureRecognizer(hoverGestureRecognizer)
        
        #if targetEnvironment(macCatalyst)
        stickerLabel.font = .systemFont(ofSize: 22, weight: .black)
        selectionView.layer.cornerRadius = 6
        #else
        stickerLabel.font = .systemFont(ofSize: 33, weight: .black)
        selectionView.layer.cornerRadius = 8
        #endif
    }
    
    override func prepareForReuse() {
        selectionView.backgroundColor = .clear
    }
    
    @objc func onHover(_ sender: UIHoverGestureRecognizer) {
        let isShowingSelected = note?.stickers?.contains(sticker) == true
        if sender.state == .began {
            selectionView.backgroundColor = isShowingSelected ? UIColor.systemFill.withAlphaComponent(0.4) : UIColor.systemFill.withAlphaComponent(0.1)
        }
        
        if sender.state == .ended || sender.state == .cancelled {
            
            selectionView.backgroundColor = isShowingSelected ? .systemFill : .clear
        }
    }
    
    func configure(note: LMNote, sticker: LMSticker) {
        self.sticker = sticker
        stickerLabel.text = String(sticker.name?.first ?? "?")
        var isShowingSelected = false
        isShowingSelected = note.stickers?.contains(sticker) == true
        selectionView.backgroundColor = isShowingSelected ? .systemFill : .clear
        self.note = note
    }
}
