//
//  LMPickerView.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-04.
//

import UIKit

class LMPickerView: UIView {
    
    var scrollView: UIScrollView
    var pickerViews: [LMAlertPickerCell]
    var candidates: [LMPickerSelectable] = []
    var pickedCandidate: LMPickerSelectable?
    
    override init(frame: CGRect) {
        self.scrollView = UIScrollView(frame: frame)
        scrollView.clipsToBounds = false
        pickerViews = []
        candidates = []
        super.init(frame: frame)
        addSubview(scrollView)
        scrollView.showsHorizontalScrollIndicator = false
    }
    
    func configure(candidates: [LMPickerSelectable], didPick: ((LMPickerSelectable) -> ())?) {
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        pickerViews = []
        for candidate in candidates {
            let candidateView = candidate.visualRepresentation(size: bounds.height)
            candidateView.addGestureRecognizer(LMTapGestureRecognizer { gesture in
                if gesture.state == .recognized {
                    didPick?(candidate)
                    self.pickedCandidate = candidate
                    self.resetSelectedState()
                }
            })

            scrollView.addSubview(candidateView)
            pickerViews.append(candidateView)
        }
        resetSelectedState()
        layoutSubviews()
    }
    
    func resetSelectedState() {
        for pickerView in self.pickerViews {
            pickerView.setSelected(selected: pickerView.candidate == self.pickedCandidate)
        }
    }
    
    required init?(coder: NSCoder) {
        self.scrollView = UIScrollView(frame: .zero)
        pickerViews = []
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = self.bounds
        pickerViews.indices.forEach { (index) in
            pickerViews[index].frame = CGRect(x:  CGFloat(index) * self.bounds.height, y: 0, width: self.bounds.height, height: self.bounds.height)
        }
        scrollView.contentSize = CGSize(width: CGFloat(pickerViews.count) * self.bounds.height, height: self.bounds.height)
    }
}

class LMColorPickerItem: LMPickerSelectable {
    override func visualRepresentation(size: CGFloat) -> (LMAlertPickerCell) {
        let imageView = LMAlertPickerCell(frame: CGRect(x: 0, y: 0, width: size, height: size), candidate: self)
        imageView.imageView.tintColor = LMNotebookDataService.NotebookColor(rawValue: identifier)?.getColor() ?? .black
        imageView.labelView.isHidden = true
        return imageView
    }
}

class LMStickerPickerItem: LMPickerSelectable {
    override func visualRepresentation(size: CGFloat) -> (LMAlertPickerCell) {
        let label = LMAlertPickerCell(frame: CGRect(x: 0, y: 0, width: size, height: size), candidate: self)
        label.labelView.text = String(identifier.first ?? "❓")
        label.imageView.isHidden = true
        return label
    }
}
