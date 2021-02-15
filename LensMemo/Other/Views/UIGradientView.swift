//
//  UIGradientView.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-11.
//

import UIKit

class UIGradientView: UIView {
    var colors: [UIColor] {
        set {
            gradientLayer.colors = newValue.map { $0.cgColor }
        }
        get {
            []
        }
    }
    var startPoint: CGPoint {
        set {
            gradientLayer.startPoint = newValue
        }
        get {
            gradientLayer.startPoint
        }
    }
    var endPoint: CGPoint {
        set {
            gradientLayer.endPoint = newValue
        }
        get {
            gradientLayer.endPoint
        }
    }
    
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        gradientLayer.colors = [UIColor.systemRed.cgColor, UIColor.systemBlue.cgColor]
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        gradientLayer.colors = [UIColor.systemRed.cgColor, UIColor.systemBlue.cgColor]
    }
}
