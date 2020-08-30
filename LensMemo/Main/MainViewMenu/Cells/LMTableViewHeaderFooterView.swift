//
//  LMTableViewHeaderFooterView.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-05.
//

import UIKit

class LMTableViewHeaderFooterView: UITableViewHeaderFooterView {
    let title = UILabel()
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        bounds = CGRect(x: 0, y: 0, width: 64, height: 64)
        configureContents()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureContents() {
        title.font = .systemFont(ofSize: 17, weight: .bold)
        title.textColor = .secondaryLabel
        title.translatesAutoresizingMaskIntoConstraints = false

        addSubview(title)

        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            title.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            title.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
        ])
    }
}
