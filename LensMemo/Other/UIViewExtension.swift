//
//  UIViewExtension.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-05.
//

import UIKit

extension UIView {
    var firstResponder: UIView? {
        guard !isFirstResponder else { return self }
        
        for subview in subviews {
            if let firstResponder = subview.firstResponder {
                return firstResponder
            }
        }
        
        return nil
    }
}
