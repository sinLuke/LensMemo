//
//  LMCameraViewNoteBookPickerController.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-05.
//

import UIKit

class LMCameraViewNoteBookPickerController: LMViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    static func getInstance(appContext: LMAppContext) -> LMCameraViewNoteBookPickerController {
        let cameraViewNoteBookPickerController = LMCameraViewNoteBookPickerController(nibName: String(describing: LMCameraViewNoteBookPickerController.self), bundle: nil)
        cameraViewNoteBookPickerController.appContext = appContext
        return cameraViewNoteBookPickerController
    }
}
