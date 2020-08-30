//
//  LMButtonView.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-29.
//

import UIKit

class LMButtonView: UIView {
    
    private let shapeView = UIGradientView()
    private let labelView = UILabel()
    private var tapGestureRecognizer: LMTouchDownGestureRecognizer?
    var needsValidate: Bool = false
    var isValidated: Bool = true
    
    var text: String? {
        didSet {
            labelView.text = text
        }
    }
    
    var onTap: () -> () = {}
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configSubviews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configSubviews()
    }
    
    @objc func onTapGesture(_ sender: UITapGestureRecognizer) {
        return
    }
    
    #if targetEnvironment(macCatalyst)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        layer.shadowOpacity = traitCollection.userInterfaceStyle == UIUserInterfaceStyle.dark ? 0.4 : 0.2
        shapeView.layer.borderColor = UIColor(named: "panelGradientEnd")?.cgColor ?? UIColor.black.cgColor
        shapeView.colors = [UIColor(named: "buttonGlowColor"), UIColor(named: "buttonColor")].compactMap { $0 }
        layer.shadowOffset = traitCollection.userInterfaceStyle == UIUserInterfaceStyle.dark ? CGSize(width: 0, height: 0) : CGSize(width: 0, height: 0.5)
        shapeView.startPoint = CGPoint(x: 0.5, y: 0)
        shapeView.endPoint = CGPoint(x: 0.5, y: 0.1)
    }
    #endif
    
    func styleButton() {
        labelView.textColor = .label
        #if targetEnvironment(macCatalyst)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = traitCollection.userInterfaceStyle == UIUserInterfaceStyle.dark ? CGSize(width: 0, height: 0) : CGSize(width: 0, height: 0.5)
        
        layer.shadowRadius = 0.5
        layer.shadowOpacity = traitCollection.userInterfaceStyle == UIUserInterfaceStyle.dark ? 0.4 : 0.2
        
        shapeView.layer.borderColor = UIColor(named: "panelGradientEnd")?.cgColor ?? UIColor.black.cgColor
        shapeView.layer.borderWidth = 1.3 / UIScreen.adjustedScale
        shapeView.colors = [UIColor(named: "buttonGlowColor"), UIColor(named: "buttonColor")].compactMap { $0 }
        shapeView.startPoint = CGPoint(x: 0.5, y: 0)
        shapeView.endPoint = CGPoint(x: 0.5, y: 0.1)
        #else
        shapeView.layer.cornerRadius = 8
        
        shapeView.colors = [.systemFill, .systemFill]
        #endif
    }
    
    func configSubviews() {
        labelView.text = "OK"
        tapGestureRecognizer = LMTouchDownGestureRecognizer(target: self, action: #selector(onTapGesture))
        tapGestureRecognizer?.onTapDown = { [weak self] in
            #if targetEnvironment(macCatalyst)
            self?.shapeView.colors = [UIColor(named: "buttonGradientStart"), UIColor(named: "buttonGradientEnd")].compactMap { $0 }
            self?.shapeView.startPoint = CGPoint(x: 0.5, y: 0)
            self?.shapeView.endPoint = CGPoint(x: 0.5, y: 1)
            self?.labelView.textColor = .white
            self?.layer.shadowRadius = 0
            self?.shapeView.layer.borderWidth = 0
            #endif
        }
        tapGestureRecognizer?.onTapRelease = { [weak self] flag in
            if flag {
                self?.onTap()
            }
            
            #if targetEnvironment(macCatalyst)
            self?.styleButton()
            #endif
        }
        
        styleButton()
        
        labelView.isUserInteractionEnabled = false
        shapeView.addGestureRecognizer(tapGestureRecognizer!)
        
        shapeView.frame = bounds
        labelView.frame = bounds
        
        shapeView.translatesAutoresizingMaskIntoConstraints = false
        labelView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(shapeView)
        shapeView.addSubview(labelView)
        shapeView.clipsToBounds = true
        
        addConstraints([
            NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: shapeView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: shapeView, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: shapeView, attribute: .leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: shapeView, attribute: .trailing, multiplier: 1, constant: 0)
        ])
        
        #if targetEnvironment(macCatalyst)
        
        labelView.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        shapeView.addConstraints([
            NSLayoutConstraint(item: shapeView, attribute: .top, relatedBy: .equal, toItem: labelView, attribute: .top, multiplier: 1, constant: -2),
            NSLayoutConstraint(item: shapeView, attribute: .bottom, relatedBy: .equal, toItem: labelView, attribute: .bottom, multiplier: 1, constant: 2),
            NSLayoutConstraint(item: shapeView, attribute: .leading, relatedBy: .equal, toItem: labelView, attribute: .leading, multiplier: 1, constant: -22),
            NSLayoutConstraint(item: shapeView, attribute: .trailing, relatedBy: .equal, toItem: labelView, attribute: .trailing, multiplier: 1, constant: 22)
        ])
        shapeView.layer.cornerRadius = 4
        
        #else
        
        labelView.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        shapeView.addConstraints([
            NSLayoutConstraint(item: shapeView, attribute: .top, relatedBy: .equal, toItem: labelView, attribute: .top, multiplier: 1, constant: -8),
            NSLayoutConstraint(item: shapeView, attribute: .bottom, relatedBy: .equal, toItem: labelView, attribute: .bottom, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: shapeView, attribute: .leading, relatedBy: .equal, toItem: labelView, attribute: .leading, multiplier: 1, constant: -16),
            NSLayoutConstraint(item: shapeView, attribute: .trailing, relatedBy: .equal, toItem: labelView, attribute: .trailing, multiplier: 1, constant: 16)
        ])
        #endif
    }
}
