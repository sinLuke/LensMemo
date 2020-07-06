//
//  LMTapGestureRecognizer.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-04.
//

import UIKit

class LMTapGestureRecognizer: UITapGestureRecognizer {
    var didTrigger: (UIGestureRecognizer) -> ()
    init(didTrigger: @escaping (UIGestureRecognizer) -> ()) {
        self.didTrigger = didTrigger
        super.init(target: nil, action: nil)
        addTarget(self, action: #selector(didTriggerSelector(_:)))
    }
    
    @objc func didTriggerSelector(_ sender: UIGestureRecognizer) {
        didTrigger(sender)
    }
}
