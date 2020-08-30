//
//  AlertTextFieldTableViewCell.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-05.
//

import UIKit

class AlertTextFieldTableViewCell: UITableViewCell {
    @IBOutlet weak var textFieldBackground: UIView!
    var onEditingEndCallBack: ((String) -> ())?
    @IBOutlet weak var inputLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    func configure(title: String, defaultValue: String?, onEditingEndCallBack: @escaping (String) -> ()) {
        inputLabel.text = "\(title):"
        textField.placeholder = defaultValue
        self.onEditingEndCallBack = onEditingEndCallBack
        textField.delegate = self
        textFieldBackground.layer.cornerRadius = 4
    }
}

extension AlertTextFieldTableViewCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        onEditingEndCallBack?(textField.text ?? "")
    }
}
