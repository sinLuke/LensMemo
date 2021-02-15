//
//  LMCollectionViewHeaderView.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-11.
//

import UIKit

class LMCollectionViewHeaderView: UICollectionReusableView {
    let label = UILabel()
    let imageView = UIImageView()
    let stackView = UIStackView()
    static let reuseIdentifier = String(describing: LMCollectionViewHeaderView.self)

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func configure(header: String, headerColor: UIColor?) {
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .firstBaseline
        
        let inset: CGFloat = 8
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: inset*2),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset/2)
        ])
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(label)
        stackView.spacing = 8
        
        label.adjustsFontForContentSizeCategory = true
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        
        var mutableHeader = header
        label.text = mutableHeader.remove(at: header.startIndex).isEmoji == true ? "\(header.first ?? "?") \(mutableHeader)" : header
        
        label.text = header
        label.numberOfLines = 0
        
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)
        stackView.setContentHuggingPriority(.required, for: .vertical)
        
        if let headerColor = headerColor {
            imageView.isHidden = false
            imageView.image = UIImage(systemName: "folder.fill")
            imageView.tintColor = headerColor
            imageView.preferredSymbolConfiguration = .init(font: UIFont.systemFont(ofSize: 20, weight: .bold))
        } else {
            imageView.isHidden = true
        }
        
        layoutIfNeeded()
    }
}
