//
//  AlertTextFieldTableViewCell.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-05.
//

import UIKit

class AlertTextFieldTableViewCell: UITableViewCell {
    var onEditingEndCallBack: ((String) -> ())?
    @IBOutlet weak var inputLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    func configure(title: String, defaultValue: String?, onEditingEndCallBack: @escaping (String) -> ()) {
        inputLabel.text = "\(title):"
        textField.placeholder = defaultValue
        self.onEditingEndCallBack = onEditingEndCallBack
        textField.addTarget(self, action: #selector(onEditingEnd), for: .editingDidEnd)
    }
    
    @objc func onEditingEnd() {
        onEditingEndCallBack?(textField.text ?? "")
    }
}
