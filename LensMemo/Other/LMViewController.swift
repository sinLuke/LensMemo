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
}
