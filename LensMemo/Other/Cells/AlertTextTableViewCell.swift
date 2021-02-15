//
//  AlertTextTableViewCell.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-05.
//

import UIKit

class AlertTextTableViewCell: UITableViewCell {
    @IBOutlet weak var messageLabel: UILabel!
    func configure(string: String, isError: Bool = false) {
        messageLabel.text = string
        messageLabel.textColor = isError ? .systemRed : .label
    }
}
