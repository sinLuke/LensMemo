//
//  LMButtonTableViewCell.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-04.
//

import UIKit

class LMButtonTableViewCell: UITableViewCell {

    @IBOutlet weak var buttonImage: UIImageView!
    @IBOutlet weak var buttonTitle: UILabel!
    @IBOutlet weak var buttonBackgroundView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        buttonBackgroundView.layer.cornerRadius = 8
        buttonBackgroundView.clipsToBounds = true
        buttonImage.tintColor = .label
    }
    
    func configure(title: String, iconSystemName: String) {
        buttonTitle.text = title
        buttonImage.image = UIImage(systemName: iconSystemName)
    }
}
