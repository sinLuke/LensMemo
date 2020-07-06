//
//  LMCameraNotebookTableViewCell.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-05.
//

import UIKit

class LMCameraNotebookTableViewCell: UITableViewCell {
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var label: UILabel!
    var isShowingSelected: Bool = false
    @IBOutlet weak var effectView: UIView!
    @IBOutlet weak var blurEffectView: UIVisualEffectView!
    @IBOutlet weak var vibrancyEffectView: UIVisualEffectView!
    var data: LMNotebook?

    @IBOutlet weak var labelBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var labelTopConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        effectView.layer.cornerRadius = 8
        effectView.clipsToBounds = true
    }
    
    func configure(data: LMNotebook?, appContext: LMAppContext) {
        self.data = data
        isShowingSelected = appContext.state.selectedNotebook?.id == data?.id
        
        self.configureViews()
    }
    
    private func configureViews() {
        
        labelTopConstraint.constant = isShowingSelected ? 12 : 8
        labelBottomConstraint.constant = isShowingSelected ? 12 : 8
        label.font = .systemFont(ofSize: isShowingSelected ? 15 : 13, weight: .bold)
        
        blurEffectView.effect = UIBlurEffect(style: isShowingSelected ? .light : .dark)
        vibrancyEffectView.effect = UIVibrancyEffect(blurEffect: .init(style: isShowingSelected ? .light : .dark), style: .label)
        if let data = self.data {
            icon.image = UIImage(systemName: isShowingSelected ? "arrow.right" : "folder")
            icon.tintColor = LMNotebookDataService.NotebookColor(rawValue: data.color ?? "lable")?.getColor() ?? (isShowingSelected ? .systemBackground : .secondaryLabel)
            label.textColor = LMNotebookDataService.NotebookColor(rawValue: data.color ?? "lable")?.getColor() ?? (isShowingSelected ? .systemBackground : .secondaryLabel)
            label.text = data.name
        } else {
            icon.image = UIImage(systemName: "plus")
            icon.tintColor = (isShowingSelected ? .systemBackground : .secondaryLabel)
            label.textColor = (isShowingSelected ? .systemBackground : .secondaryLabel)
            label.text = "Create a new Notebook"
        }
        
        self.layoutIfNeeded()
    }
}
