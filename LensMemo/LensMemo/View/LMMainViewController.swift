//
//  LMMainViewController.swift
//  LensMemo-iOS
//
//  Created by Luke Yin on 2020-07-01.
//

import UIKit

class LMMainViewController: LMViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    static func getInstance(context: LMAppContext) -> LMMainViewController {
        let mainViewController = LMMainViewController(nibName: String(describing: LMMainViewController.self), bundle: nil)
        mainViewController.context = context
        return mainViewController
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var shouldAutorotate: Bool {
        return true
    }
}
