//
//  UIWindowsConfigure.swift
//  UIWindows
//
//  Created by Luke Yin on 2019-12-02.
//  Copyright © 2019 sinLuke. All rights reserved.
//

import UIKit

public struct UIWindowsConfigure {
    
    public static var defaultConfig = UIWindowsConfigure(minHeight: 300.0, minWidth: 200.0, tintColor: .systemBlue, cornerAdjustRadius: 20.0, barHeight: 33.0, windowEdgeWidth: 0)
    
    public init(minHeight: CGFloat = 300.0, minWidth: CGFloat = 200.0, tintColor: UIColor = .systemBlue, cornerAdjustRadius: CGFloat = 20.0, barHeight: CGFloat = 33.0, windowEdgeWidth: CGFloat = 0) {
        self.minHeight = minHeight
        self.minWidth = minWidth
        self.tintColor = tintColor
        self.cornerResponsRadius = cornerAdjustRadius
        self.barHeight = barHeight
        self.windowEdgeWidth = windowEdgeWidth
    }
    
    let minHeight: CGFloat
    let minWidth: CGFloat
    let tintColor: UIColor
    let cornerResponsRadius: CGFloat
    let barHeight: CGFloat
    let windowEdgeWidth: CGFloat
}
