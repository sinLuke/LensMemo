//
//  LMCollectionViewHeaderView.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-11.
//

import UIKit

class LMCollectionViewHeaderView: UICollectionReusableView {
    let label = UILabel()
    static let reuseIdentifier = String(describing: LMCollectionViewHeaderView.self)

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func configure(string: String) {
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        let inset: CGFloat = 8
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            label.topAnchor.constraint(equalTo: topAnchor, constant: inset*2),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset/2)
        ])
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.text = string
    }
}
