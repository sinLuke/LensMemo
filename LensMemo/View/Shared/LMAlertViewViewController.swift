//
//  LMAlertViewViewController.swift
//  LensMemo-iOS
//
//  Created by Luke Yin on 2020-07-01.
//

import UIKit

class LMAlertViewViewController: LMViewController {
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var alertTitle: UILabel!
    @IBOutlet weak var alertMessage: UILabel!
    @IBOutlet weak var stackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 0)
        view.layer.shadowRadius = 16
        view.layer.shadowOpacity = 0.6
    }
    

    private func setButtons(buttons: [Button]) {
        stackView.arrangedSubviews.forEach { view in
            if view is UIButton {
                view.removeFromSuperview()
            }
        }
        buttons.forEach { button in
            let buttonView = LMButton(onTapCallBack: button.onTap)
            buttonView.setTitle(button.title, for: .normal)
            buttonView.backgroundColor = button.backgroundColor
            buttonView.setTitleColor(.systemBackground, for: .normal)
            buttonView.titleLabel?.font = .systemFont(ofSize: 19, weight: .medium)
            stackView.addArrangedSubview(buttonView)
        }
    }
    
    private func setIcon(image: UIImage, color: UIColor) {
        iconView.image = image
        iconView.tintColor = color
    }
    
    static func getInstance(icon: UIImage?, color: UIColor?, title: String?, message: String?, buttons: [Button]) -> LMAlertViewViewController {
        let alert = LMAlertViewViewController(nibName: String(describing: LMAlertViewViewController.self), bundle: nil)
        
        alert.afterViewLoaded {
            if let icon = icon {
                alert.setIcon(image: icon, color: color ?? .label)
            } else {
                alert.iconView.removeFromSuperview()
            }
            alert.setButtons(buttons: buttons)
            if let title = title {
                alert.alertTitle.text = title
            } else {
                alert.alertTitle.removeFromSuperview()
            }
            if let message = message {
                alert.alertMessage.text = message
            } else {
               alert.alertMessage.removeFromSuperview()
            }
        }
        
        return alert
    }
    
    struct Button {
        var title: String = "Dismiss"
        var backgroundColor: UIColor = .label
        var onTap: () -> ()
    }
}
