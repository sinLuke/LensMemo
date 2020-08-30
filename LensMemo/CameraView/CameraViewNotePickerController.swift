//
//  LMCameraViewNotePickerController.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-05.
//

import UIKit

class LMCameraViewNotePickerController: LMViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    static func getInstance(appContext: LMAppContext) -> LMCameraViewNotePickerController {
        let cameraViewNotePickerController = LMCameraViewNotePickerController(nibName: String(describing: LMCameraViewNotePickerController.self), bundle: nil)
        cameraViewNotePickerController.appContext = appContext
        return cameraViewNotePickerController
    }
}
