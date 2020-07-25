//
//  LMCameraViewModel.swift
//  LensMemo-iOS
//
//  Created by Luke Yin on 2020-07-01.
//

import UIKit
import AVFoundation

class LMCameraViewModel: ViewModel {
    var captureSession = AVCaptureSession()
    var stillImageOutput: AVCapturePhotoOutput?
    var captureDeviceInput: AVCaptureDeviceInput?
    let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    weak var delegate: LMCameraViewModelDelegate?
    var format: AVCaptureDevice.Format?
    
    func configure(delegate: LMCameraViewModelDelegate) {
        self.delegate = delegate
    }

    func setUpCaptureSession() {
        sessionQueue.async {
            self.configureSession()
        }
        
        
    }
    
    private func configureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
            else {
                delegate?.showError(error: LMError.cameraError)
                return
        }
        
        do {
            captureDeviceInput = try AVCaptureDeviceInput(device: backCamera)
        }
            
        catch let error {
            delegate?.showError(error: error)
        }
        
        stillImageOutput = AVCapturePhotoOutput()
        
        if
            let captureDeviceInput = self.captureDeviceInput,
            let stillImageOutput = self.stillImageOutput,
            captureSession.canAddInput(captureDeviceInput) && captureSession.canAddOutput(stillImageOutput) {
            stillImageOutput.isHighResolutionCaptureEnabled = true
            stillImageOutput.maxPhotoQualityPrioritization = .quality
            captureSession.addInput(captureDeviceInput)
            captureSession.addOutput(stillImageOutput)
            format = captureDeviceInput.device.activeFormat
            
            DispatchQueue.main.async {
                self.delegate?.sessionIsReady(session: self.captureSession)
            }
        } else {
            DispatchQueue.main.async {
                self.delegate?.showError(error: LMError.cameraError)
            }
        }
        
        captureSession.commitConfiguration()
    }
    
    func startCaptureSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession.startRunning()
            main { [weak self] in
                self?.delegate?.sessionHasStarted()
            }
        }
    }
    
    func pauseSession() {
        self.captureSession.stopRunning()
    }
    
    func startTakingPicture() {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        
        if let orientation = delegate?.videoPreviewLayerOrientation(), let photoOutputConnection = self.stillImageOutput?.connection(with: .video) {
            photoOutputConnection.videoOrientation = orientation
        }
        settings.isHighResolutionPhotoEnabled = true
        stillImageOutput?.maxPhotoQualityPrioritization = .quality
        settings.photoQualityPrioritization = .quality
        stillImageOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    func focus(with focusMode: AVCaptureDevice.FocusMode,
                       exposureMode: AVCaptureDevice.ExposureMode,
                       at devicePoint: CGPoint,
                       monitorSubjectAreaChange: Bool) {
        
        sessionQueue.async {
            guard let device = self.captureDeviceInput?.device else { return }
            do {
                try device.lockForConfiguration()
                
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = focusMode
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode
                }
                
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
}

extension LMCameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation()
            else {
                delegate?.showError(error: LMError.cameraError)
                return
        }
        delegate?.pictureDidTaken(data: data)
    }
}

protocol LMCameraViewModelDelegate where Self: UIViewController {
    func videoPreviewLayerOrientation() -> AVCaptureVideoOrientation?
    func sessionIsReady(session: AVCaptureSession)
    func showError(error: Error)
    func sessionHasStarted()
    func pictureDidTaken(data: Data)
}
