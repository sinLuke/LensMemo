//
//  LMButton.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-01.
//

import UIKit

class LMButton: UIButton {

    weak var weakSelf: UIButton?
    var onTapCallBack: (() -> ())?
    
    convenience init(onTapCallBack: @escaping () -> ()) {
        self.init(type: .custom)
        self.onTapCallBack = onTapCallBack
        weakSelf = self
        addTarget(self, action: #selector(onTap), for: .touchUpInside)
    }
    
    @objc func onTap() {
        onTapCallBack?()
    }
}
