//
//  LMNavigationController.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-04.
//

import UIKit

class LMNavigationController: UINavigationController {
    let appContext: LMAppContext

    init(appContext: LMAppContext, rootViewController: UIViewController) {
        self.appContext = appContext
        super.init(rootViewController: rootViewController)
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func appStateDidSet() {
        return
    }
}
