//
//  LMNotebookTableViewCell.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-04.
//

import UIKit

class LMNotebookTableViewCell: UITableViewCell {
    @IBOutlet weak var folderIcon: UIImageView!
    @IBOutlet weak var nameTitle: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    
    func configure(data: LMNotebook) {
        nameTitle.text = data.name
        countLabel.isHidden = false
        countLabel.text = String.localizedStringWithFormat(NSLocalizedString("%d notes", comment: "%d notes"), data.notes?.count ?? 0)
        folderIcon.image = UIImage(systemName: "folder.fill")
        folderIcon.tintColor = LMNotebookDataService.NotebookColor(rawValue: data.color ?? "default")?.getColor() ?? .label
    }
    
    func configAsJustShot() {
        nameTitle.text = NSLocalizedString("Just Shot", comment: "Just Shot")
        countLabel.isHidden = true
        folderIcon.image = UIImage(systemName: "camera")
        folderIcon.tintColor = .label
    }
    
    func configAsCover() {
        nameTitle.text = NSLocalizedString("Cover", comment: "Cover")
        countLabel.isHidden = true
        folderIcon.image = UIImage(systemName: "star")
        folderIcon.tintColor = .label
    }
    
    func configAsRecentViewed() {
        nameTitle.text = NSLocalizedString("Recently Viewed", comment: "Recently Viewed")
        countLabel.isHidden = true
        folderIcon.image = UIImage(systemName: "clock")
        folderIcon.tintColor = .label
    }
    
    func configAsSetting() {
        nameTitle.text = NSLocalizedString("Setting", comment: "Setting")
        countLabel.isHidden = true
        folderIcon.image = UIImage(systemName: "gear")
        folderIcon.tintColor = .label
    }
}
