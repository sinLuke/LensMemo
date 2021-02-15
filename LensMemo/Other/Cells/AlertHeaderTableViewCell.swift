//
//  AlertHeaderTableViewCell.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-08-24.
//

import UIKit

class AlertHeaderTableViewCell: UITableViewCell {

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var headerIcon: UIImageView!
    @IBOutlet weak var gradientView: UIGradientView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
    func configure(title: String, icon: UIImage?, color: UIColor?) {
        headerLabel.text = title
        headerIcon.image = icon ?? UIImage(systemName: "info.circle.fill")
        headerIcon.tintColor = color ?? .label
        
        #if targetEnvironment(macCatalyst)
        headerLabel.font = .systemFont(ofSize: 17, weight: .medium)
        headerLabel.textColor = UIColor.label.withAlphaComponent(0.8)
        headerIcon.preferredSymbolConfiguration = .init(font: .systemFont(ofSize: 17, weight: .medium))
        #else
        headerLabel.font = .systemFont(ofSize: 28, weight: .bold)
        headerLabel.textColor = .label
        headerIcon.preferredSymbolConfiguration = .init(font: .systemFont(ofSize: 28, weight: .bold))
        #endif
    }
}
