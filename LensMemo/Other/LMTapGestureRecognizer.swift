//
//  LMTapGestureRecognizer.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-04.
//

import UIKit

class LMTapGestureRecognizer: UITapGestureRecognizer {
    var maxiumForce: CGFloat = 0.0
    
    var didTrigger: (UIGestureRecognizer) -> ()
    init(didTrigger: @escaping (UIGestureRecognizer) -> ()) {
        self.didTrigger = didTrigger
        super.init(target: nil, action: nil)
        addTarget(self, action: #selector(didTriggerSelector(_:)))
    }
    
    @objc func didTriggerSelector(_ sender: UIGestureRecognizer) {
        didTrigger(sender)
    }
    
    override init(target: Any?, action: Selector?) {
        didTrigger = { _ in }
        super.init(target: target, action: action)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        touches.forEach { (touch) in
            if touch.force > maxiumForce {
                maxiumForce = touch.force
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        touches.forEach { (touch) in
            if touch.force > maxiumForce {
                maxiumForce = touch.force
            }
        }
    }
}
