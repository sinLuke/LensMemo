//
//  AlertPickerTableViewCell.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-05.
//

import UIKit

class AlertPickerTableViewCell: UITableViewCell {
    
    let pickerView = LMPickerView()
    let labelView = UILabel()
    
    let candidates = [
        LMColorPickerItem(identifier: LMNotebookDataService.NotebookColor.black.rawValue),
        LMColorPickerItem(identifier: LMNotebookDataService.NotebookColor.red.rawValue),
        LMColorPickerItem(identifier: LMNotebookDataService.NotebookColor.orange.rawValue),
        LMColorPickerItem(identifier: LMNotebookDataService.NotebookColor.yellow.rawValue),
        LMColorPickerItem(identifier: LMNotebookDataService.NotebookColor.green.rawValue),
        LMColorPickerItem(identifier: LMNotebookDataService.NotebookColor.teal.rawValue),
        LMColorPickerItem(identifier: LMNotebookDataService.NotebookColor.blue.rawValue),
        LMColorPickerItem(identifier: LMNotebookDataService.NotebookColor.purple.rawValue)
    ]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addSubview(pickerView)
        addSubview(labelView)
        
        labelView.text = NSLocalizedString("Pick a color for your notebook:", comment: "Pick a color for your notebook:")
        labelView.sizeToFit()
        labelView.font = .systemFont(ofSize: 17, weight: .medium)
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        labelView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint(item: pickerView, attribute: .top, relatedBy: .equal, toItem: labelView, attribute: .bottom, multiplier: 1, constant: 8).isActive = true
        NSLayoutConstraint(item: labelView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 16).isActive = true
        NSLayoutConstraint(item: pickerView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: -16).isActive = true
        NSLayoutConstraint(item: pickerView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 16).isActive = true
        NSLayoutConstraint(item: pickerView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -16).isActive = true
        NSLayoutConstraint(item: labelView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 16).isActive = true
        NSLayoutConstraint(item: labelView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -16).isActive = true
        NSLayoutConstraint(item: pickerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 36).isActive = true
        NSLayoutConstraint(item: labelView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: labelView.bounds.height).isActive = true
    }
    
    func configure(callBack: @escaping ((String) -> ())) {
        
        pickerView.pickedCandidate = LMColorPickerItem(identifier: LMNotebookDataService.NotebookColor.black.rawValue)
        pickerView.configure(candidates: candidates) { (selected) in
            callBack(selected.identifier)
        }
    }
}
