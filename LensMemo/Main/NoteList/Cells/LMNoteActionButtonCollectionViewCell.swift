//
//  LMNoteActionButtonCollectionViewCell.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-08-30.
//

import UIKit

class LMNoteActionButtonCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var buttonBackground: UIView!
    @IBOutlet weak var buttonLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        buttonBackground.layer.cornerRadius = 8
        // Initialization code
    }
    
    func configure(title: String, backgroundColor: UIColor, textColor: UIColor) {
        self.buttonLabel.text = title
        self.buttonLabel.textColor = textColor
        self.buttonBackground.backgroundColor = backgroundColor
    }
}
