//
//  LMCameraViewModel.swift
//  LensMemo-iOS
//
//  Created by Luke Yin on 2020-07-01.
//

import UIKit
import AVFoundation

class LMCameraViewModel: ViewModel {
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCapturePhotoOutput?
    var captureDeviceInput: AVCaptureDeviceInput?
    
    weak var delegate: LMCameraViewModelDelegate?
    var format: AVCaptureDevice.Format?
    
    func configure(delegate: LMCameraViewModelDelegate) {
        self.delegate = delegate
    }

    func setUpCaptureSession() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
            else {
                delegate?.showError(message: "Error: Unable to access back camera!")
                return
        }
        
        do {
            captureDeviceInput = try AVCaptureDeviceInput(device: backCamera)
        }

        catch let error {
            delegate?.showError(message: "Error: Unable to initialize back camera:  \(error.localizedDescription)")
        }
        
        stillImageOutput = AVCapturePhotoOutput()
        
        if
            let captureSession = self.captureSession,
            let captureDeviceInput = self.captureDeviceInput,
            let stillImageOutput = self.stillImageOutput,
            captureSession.canAddInput(captureDeviceInput) && captureSession.canAddOutput(stillImageOutput) {
            stillImageOutput.isHighResolutionCaptureEnabled = true
            captureSession.addInput(captureDeviceInput)
            captureSession.addOutput(stillImageOutput)
            format = captureDeviceInput.device.activeFormat
            delegate?.sessionIsReady(session: captureSession)
        } else {
            delegate?.showError(message: "Error: Unable to add input or out put devices")
        }
    }
    
    func startCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.sessionHasStarted()
            }
        }
    }
    
    func startTakingPicture() {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        settings.isHighResolutionPhotoEnabled = true
        stillImageOutput?.maxPhotoQualityPrioritization = .quality
        settings.photoQualityPrioritization = .quality
        stillImageOutput?.capturePhoto(with: settings, delegate: self)
    }
}

extension LMCameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation()
            else {
                delegate?.showError(message: "Error: Unable to process the photo")
                return
        }
        delegate?.pictureDidTaken(data: data)
    }
}

protocol LMCameraViewModelDelegate where Self: UIViewController {
    func sessionIsReady(session: AVCaptureSession)
    func showError(message: String)
    func sessionHasStarted()
    func pictureDidTaken(data: Data)
}
