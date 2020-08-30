//
//  UIColorExtension.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-25.
//

import UIKit

extension UIColor {
    public convenience init(compactColor: Int64?) {
        guard let compactColor = compactColor else {
            self.init(cgColor: CGColor(srgbRed: 0.0, green: 0.0, blue: 0.0, alpha: 1.0))
            return
        }
        let red = compactColor % 256
        let green = (compactColor / 256) % 256
        let blue = (compactColor / (256 * 256))
        self.init(cgColor: CGColor(srgbRed: CGFloat(red) / 255.0, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: 1.0))
    }
}
