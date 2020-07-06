//
//  LMViewController.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-01.
//

import UIKit

class LMViewController: UIViewController {

    var appContext: LMAppContext!
    var viewLoadingQueue = DispatchQueue(label: "viewLoadingQueue", qos: .userInitiated, attributes: .initiallyInactive, autoreleaseFrequency: .inherit, target: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewLoadingQueue.activate()
        // Do any additional setup after loading the view.
    }

    func afterViewLoaded(_ callBack: @escaping () -> ()) {
        viewLoadingQueue.async {
            DispatchQueue.main.async {
                callBack()
            }
        }
    }
    
    func addSubViewConreoller(_ child: UIViewController, in containerView: UIView) {
        child.didMove(toParent: self)
        containerView.addSubview(child.view)
        self.addChild(child)
        guard let childView = child.view else { return }
        NSLayoutConstraint(item: childView, attribute: .bottom, relatedBy: .equal, toItem: containerView, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: childView, attribute: .leading, relatedBy: .equal, toItem: containerView, attribute: .leading, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: childView, attribute: .trailing, relatedBy: .equal, toItem: containerView, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: childView, attribute: .top, relatedBy: .equal, toItem: containerView, attribute: .top, multiplier: 1, constant: 0).isActive = true
    }
    
    func appStateDidSet() {
        return
    }
}
