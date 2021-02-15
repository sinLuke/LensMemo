//
//  LMCircleView.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-04.
//

import UIKit

class LMCircleView: UIView {
    var isSelected: Bool = false {
        didSet {
            selectedView.isHidden = !isSelected
        }
    }
    var selectedView = UIView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        selectedView.backgroundColor = .systemBackground
        self.addSubview(selectedView)
        layoutSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
        selectedView.frame = CGRect(x: (1/4) * bounds.width, y: (1/4) * bounds.height ,width: (1/2) * bounds.width, height: (1/2) * bounds.height)
    }
}
