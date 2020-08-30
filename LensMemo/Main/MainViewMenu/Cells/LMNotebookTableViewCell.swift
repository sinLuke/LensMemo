//
//  LMNotebookTableViewCell.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-04.
//

import UIKit

class LMNotebookTableViewCell: UITableViewCell {
    @IBOutlet weak var folderIcon: UIImageView!
    @IBOutlet weak var stickerIcon: UILabel!
    @IBOutlet weak var nameTitle: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var countContainerView: UIView!
    @IBOutlet weak var countContainerLabel: UILabel!
    
    @IBOutlet weak var leadingMargin: NSLayoutConstraint!
    @IBOutlet weak var topConstarint: NSLayoutConstraint!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    override func awakeFromNib() {
        super.awakeFromNib()
        folderIcon.isHidden = true
        stickerIcon.isHidden = true
        #if targetEnvironment(macCatalyst)
        accessoryType = .none
        nameTitle.font = .systemFont(ofSize: 17)
        topConstarint.constant = 6
        bottomConstraint.constant = 6
        countLabel.isHidden = true
        countContainerView.isHidden = true
        leadingMargin.constant = 20
        #else
        accessoryType = .disclosureIndicator
        nameTitle.font = .systemFont(ofSize: 17, weight: .medium)
        topConstarint.constant = 9
        bottomConstraint.constant = 9
        countLabel.isHidden = false
        countContainerView.isHidden = true
        leadingMargin.constant = 12
        #endif
    }
    
    func configure(data: LMNotebook, appContext: LMAppContext) {
        nameTitle.text = data.name
        countLabel.text = String.localizedStringWithFormat(NSLocalizedString("%d notes", comment: "%d notes"), data.notes?.count ?? 0)
        countContainerLabel.text = "\(data.notes?.count ?? 0)"
        #if targetEnvironment(macCatalyst)
        countContainerView.isHidden = data.notes?.count ?? 0 <= 0
        #endif
        folderIcon.image = UIImage(systemName: "folder.fill")
        folderIcon.tintColor = LMNotebookDataService.NotebookColor(rawValue: data.color ?? "default")?.getColor() ?? .label
        stickerIcon.isHidden = true
        folderIcon.isHidden = false
        
        #if targetEnvironment(macCatalyst)
        backgroundColor = appContext.state.selectedNotebook == data ? .systemFill : .clear
        #endif
    }
    
    func configure(sticker: LMSticker, appContext: LMAppContext) {
        var stickerName = sticker.name ?? "No name"
        nameTitle.text = stickerName.remove(at: stickerName.startIndex).isEmoji == true ? stickerName : sticker.name ?? "No name"
        if nameTitle.text?.count == 0 {
            nameTitle.text = "Sticker"
        }
        countLabel.text = String.localizedStringWithFormat(NSLocalizedString("%d notes", comment: "%d notes"), sticker.notes?.count ?? 0)
        countContainerLabel.text = "\(sticker.notes?.count ?? 0)"
        #if targetEnvironment(macCatalyst)
        countContainerView.isHidden = sticker.notes?.count ?? 0 <= 0
        #endif
        stickerIcon.text = String(sticker.name?.first ?? Character("?"))
        folderIcon.tintColor = .label
        stickerIcon.isHidden = false
        folderIcon.isHidden = true
        
        if appContext.state.selectedSticker == sticker {
            print("a")
        }
        
        #if targetEnvironment(macCatalyst)
        backgroundColor = appContext.state.selectedSticker == sticker ? .systemFill : .clear
        #endif
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        countContainerView.layer.cornerRadius = countContainerView.frame.height / 2
    }
    
    func configAsJustShot(appContext: LMAppContext) {
        nameTitle.text = NSLocalizedString("Just Shot", comment: "Just Shot")
        countLabel.isHidden = true
        countContainerLabel.isHidden = true
        folderIcon.image = UIImage(systemName: "camera")
        folderIcon.tintColor = .label
        stickerIcon.isHidden = true
        folderIcon.isHidden = false
    }
    
    func configAsCover(appContext: LMAppContext) {
        nameTitle.text = NSLocalizedString("Cover", comment: "Cover")
        countLabel.isHidden = true
        countContainerLabel.isHidden = true
        folderIcon.image = UIImage(systemName: "star")
        folderIcon.tintColor = .label
        stickerIcon.isHidden = true
        folderIcon.isHidden = false
    }
    
    func configAsRecentViewed(appContext: LMAppContext) {
        nameTitle.text = NSLocalizedString("Recently Viewed", comment: "Recently Viewed")
        countLabel.isHidden = true
        countContainerLabel.isHidden = true
        folderIcon.image = UIImage(systemName: "clock")
        folderIcon.tintColor = .label
        stickerIcon.isHidden = true
        folderIcon.isHidden = false
    }
    
    func configAsSetting(appContext: LMAppContext) {
        nameTitle.text = NSLocalizedString("Setting", comment: "Setting")
        countLabel.isHidden = true
        countContainerLabel.isHidden = true
        folderIcon.image = UIImage(systemName: "gear")
        folderIcon.tintColor = .label
        stickerIcon.isHidden = true
        folderIcon.isHidden = false
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        awakeFromNib()
    }
}
