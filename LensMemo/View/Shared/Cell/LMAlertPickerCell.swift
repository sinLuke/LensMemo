//
//  LMAlertPickerCell.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-06.
//

import UIKit

class LMAlertPickerCell: UIView {
    
    var imageView: UIImageView
    var labelView: UILabel
    var candidate: LMPickerSelectable
    
    init(frame: CGRect, candidate: LMPickerSelectable) {
        self.candidate = candidate
        imageView = UIImageView(frame: frame)
        labelView = UILabel(frame: frame)
        labelView.font = .systemFont(ofSize: 32, weight: .black)
        labelView.textAlignment = .center
        super.init(frame: frame)
        addSubview(imageView)
        addSubview(labelView)
        layer.cornerRadius = 8
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setSelected(selected: Bool) {
        imageView.image = UIImage(systemName: selected ? "largecircle.fill.circle" : "circle")
        if !labelView.isHidden {
            backgroundColor = selected ? .systemFill : .clear
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        labelView.frame = bounds
    }
}

class LMPickerSelectable: Equatable {
    
    var identifier: String
    
    init(identifier: String) {
        self.identifier = identifier
    }
    
    static func == (lhs: LMPickerSelectable, rhs: LMPickerSelectable) -> Bool {
        lhs.identifier == rhs.identifier
    }
    
    func visualRepresentation(size: CGFloat) -> LMAlertPickerCell {
        return LMAlertPickerCell(frame: .zero, candidate: self)
    }
}
