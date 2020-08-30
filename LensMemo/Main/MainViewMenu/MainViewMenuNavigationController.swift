//
//  MainViewMenuNavigationController.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-04.
//

import UIKit

class MainViewMenuNavigationController: LMNavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.clipsToBounds = false
        // Do any additional setup after loading the view.
    }
    
    override func appStateDidSet() {
        super.appStateDidSet()
    }
}
