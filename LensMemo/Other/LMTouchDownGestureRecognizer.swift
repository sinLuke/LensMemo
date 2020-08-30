//
//  LMTouchDownGestureRecognizer.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-29.
//

import UIKit

class LMTouchDownGestureRecognizer: UIGestureRecognizer {
    var onTapDown: () -> () = {}
    var onTapRelease: (Bool) -> () = { _ in }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        onTapDown()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        if let touch = touches.first {
            if self.view?.bounds.contains(touch.location(in: self.view)) ?? false {
                onTapRelease(true)
                return
            }
        }
        onTapRelease(false)
    }
}
