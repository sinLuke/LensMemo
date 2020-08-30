//
//  UIScreenExtension.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-08-24.
//

import UIKit

extension UIScreen {
    static var adjustedScale: CGFloat {
        #if targetEnvironment(macCatalyst)
        return UIScreen.main.scale * 0.77
        #else
        return UIScreen.main.scale
        #endif
    }
}
