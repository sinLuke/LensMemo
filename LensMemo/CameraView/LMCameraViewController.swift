//
//  LMCameraViewController.swift
//  LensMemo-iOS
//
//  Created by Luke Yin on 2020-07-01.
//

import UIKit
import AVFoundation
import CoreML
import Vision
import ImageIO

class LMCameraViewController: LMViewController {
    // MARK: - IBOutlet
    
    @IBOutlet weak var previewView: LMCameraPreview!
    @IBOutlet weak var takePictureButton: UIButton!
    @IBOutlet weak var takePictureImage: UIImageView!
    @IBOutlet weak var cameraEffectView: UIView!
    @IBOutlet weak var imageEffectView: UIImageView!
    @IBOutlet weak var currentStatusMessageLabel: UILabel!
    @IBOutlet weak var shadowEffectView: UIView!
    @IBOutlet weak var focusIcon: UIImageView!
    
    @IBOutlet weak var stickerPickingView: UITableView!
    @IBOutlet weak var notebookPickingView: UITableView!
    @IBOutlet weak var cameraButtonContainerView: UIVisualEffectView!
    
    @IBOutlet weak var networkIndicator: UIView!
    @IBOutlet weak var networkIndicatorLabel: UILabel!
    var isInternetWorking: Bool = true {
        didSet {
            if isViewLoaded {
                networkIndicator.isHidden = isInternetWorking
                networkIndicatorLabel.text = l("No internet")
            }
        }
    }
    
    var imageEffectEndingReference: CGRect = CGRect(x: 0, y: 0, width: 100, height: 100)
    var cameraNotebookDelegate: LMCameraViewNotebookTableViewDelegate?
    var cameraStickerDelegate: LMCameraViewStickerTableViewDelegate?
    
    var windowOrientation: UIInterfaceOrientation {
        return view.window?.windowScene?.interfaceOrientation ?? .unknown
    }
    
    // MARK: - Property
    
    var viewModel = LMCameraViewModel()
    
    // MARK: - View State
    
    var state: State = .root {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.cameraEffectView.alpha = 0.0
                self.currentStatusMessageLabel.isHidden = true
                self.takePictureButton.isHidden = true
                self.takePictureImage.isHidden = true
                self.stickerPickingView.isHidden = true
                self.notebookPickingView.isHidden = true
                self.previewView.isHidden = false
                switch self.state {
                case let .error(error):
                    let alert = LMAlertViewViewController.getInstance(error: error)
                    self.present(alert, animated: false, completion: nil)
                case .root:
                    self.currentStatusMessageLabel.text = "Starting Camera"
                    self.currentStatusMessageLabel.isHidden = false
                    self.previewView.isHidden = true
                    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                        self?.viewModel.setUpCaptureSession()
                    }
                case let .loading(message):
                    self.currentStatusMessageLabel.text = message
                    self.currentStatusMessageLabel.isHidden = false
                    self.previewView.isHidden = true
                case .takingPicture:
                    self.cameraEffectView.alpha = 1.0
                    UIView.animate(withDuration: 0.1) {
                        self.cameraEffectView.alpha = 0.0
                    }
                case  .pictureRecieved:
                    self.stickerPickingView.isHidden = false
                    self.notebookPickingView.isHidden = false
                case .ready:
                    self.takePictureButton.isHidden = false
                    self.takePictureImage.isHidden = false
                    self.stickerPickingView.isHidden = false
                    self.notebookPickingView.isHidden = false
                    return
                case .pause:
                    self.currentStatusMessageLabel.text = "Resuming Camera"
                    self.currentStatusMessageLabel.isHidden = false
                    self.previewView.isHidden = true
                }
            }
        }
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.delegate = self
        networkIndicator.isHidden = isInternetWorking
        networkIndicatorLabel.text = l("No internet")
        shadowEffectView.layer.shadowColor = UIColor.black.cgColor
        shadowEffectView.layer.shadowOffset = CGSize(width: 0, height: 0)
        shadowEffectView.layer.shadowRadius = 16
        shadowEffectView.layer.shadowOpacity = 0.6
        
        cameraButtonContainerView.layer.cornerRadius = 19
        cameraButtonContainerView.clipsToBounds = true
        
        let focusAndExposeTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(focusAndExposeTap))
        shadowEffectView.addGestureRecognizer(focusAndExposeTapGestureRecognizer)
        
        do {
            cameraStickerDelegate = try LMCameraViewStickerTableViewDelegate(tableView: stickerPickingView, appContext: appContext)
            cameraNotebookDelegate = try LMCameraViewNotebookTableViewDelegate(tableView: notebookPickingView, appContext: appContext)
        } catch (let error) {
            state = .error(error: error)
        }
        
        stickerPickingView.delegate = cameraStickerDelegate
        stickerPickingView.dataSource = cameraStickerDelegate
        
        notebookPickingView.delegate = cameraNotebookDelegate
        notebookPickingView.dataSource = cameraNotebookDelegate
        
        focusIcon.alpha = 0.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        switch state {
        case .pause:
            viewModel.startCaptureSession()
        default:
            state = .root
        }
        
        takePictureButton.layer.cornerRadius = takePictureButton.bounds.width / 2
        takePictureButton.clipsToBounds = true
        cameraNotebookDelegate?.updateTableViewContentInset()
        cameraStickerDelegate?.updateTableViewContentInset()
        
        if appContext.state.selectedNotebook == nil, !(appContext.noteBookService.fetchedResultsController.fetchedObjects?.isEmpty == true) {
            appContext.state.selectedNotebook = appContext.noteBookService.fetchedResultsController.fetchedObjects?.first
        }
        
        cameraNotebookDelegate?.tableView?.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        viewModel.pauseSession()
        state = .pause
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cameraNotebookDelegate?.updateTableViewContentInset()
        cameraStickerDelegate?.updateTableViewContentInset()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if let videoPreviewLayerConnection = previewView.videoPreviewLayer.connection {
            let deviceOrientation = UIDevice.current.orientation
            guard let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation),
                deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                    return
            }
            
            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
        }
        
        cameraStickerDelegate?.updateTableViewContentInset()
        cameraNotebookDelegate?.updateTableViewContentInset()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var shouldAutorotate: Bool {
        return true
    }
    
    @IBAction func takePictureButtonDidTap(_ sender: Any) {
        state = .takingPicture
        viewModel.startTakingPicture()
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    @IBAction func toggleCameraTapped(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "toggleCamerView"), object: nil)
    }
    
    @objc private func focusAndExposeTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let devicePoint = previewView.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: gestureRecognizer.location(in: gestureRecognizer.view))
        self.focusIcon.frame = CGRect(x: gestureRecognizer.location(in: gestureRecognizer.view).x - 60, y: gestureRecognizer.location(in: gestureRecognizer.view).y - 60, width: 120, height: 120)
        focusIcon.transform = CGAffineTransform(scaleX: 2, y: 2)
        focusIcon.alpha = 0.0
        UIView.animate(withDuration: 0.1, animations: {
            self.focusIcon.alpha = 1.0
            self.focusIcon.transform = .identity
        }, completion: { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                UIView.animate(withDuration: 0.3, animations: {
                    self.focusIcon.alpha = 0.5
                    self.focusIcon.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                }, completion: { _ in
                    UIView.animate(withDuration: 0.3, animations: {
                        self.focusIcon.alpha = 1.0
                        self.focusIcon.transform = .identity
                    }, completion: { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            UIView.animate(withDuration: 0.3, animations: {
                                self.focusIcon.alpha = 0.0
                            })
                        }
                    })
                })
            }
            
        })
        viewModel.focus(with: .autoFocus, exposureMode: .autoExpose, at: devicePoint, monitorSubjectAreaChange: true)
    }
    
    static func getInstance(appContext: LMAppContext) -> LMCameraViewController {
        let cameraViewController = LMCameraViewController(nibName: String(describing: LMCameraViewController.self), bundle: nil)
        cameraViewController.appContext = appContext
        return cameraViewController
    }
}

extension LMCameraViewController: LMCameraViewModelDelegate {
    
    func videoPreviewLayerOrientation() -> AVCaptureVideoOrientation? {
        return previewView.videoPreviewLayer.connection?.videoOrientation
    }
    
    func showError(error: Error) {
        state = .error(error: error)
    }
    
    func sessionIsReady(session: AVCaptureSession) {
        previewView.session = session
        var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
        if self.windowOrientation != .unknown {
            if let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: self.windowOrientation) {
                initialVideoOrientation = videoOrientation
            }
        }
        
        self.previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
        self.previewView.videoPreviewLayer.videoGravity = .resizeAspectFill
        self.state = .loading(message: "Starting Camera Session")
        self.viewModel.startCaptureSession()
    }
    
    func sessionHasStarted() {
        state = .ready
    }
    
    func pictureDidTaken(data: Data) {
        self.state = .pictureRecieved
        guard let image = UIImage(data: data) else {
            state = .error(error: LMError.errorWhenLoadImage)
            return
        }
        self.appContext.noteService.addNote(name: "", message: "", image: UIImage(data: data), stickers: [self.appContext.state.applyingSticker].compactMap { $0 }, result: { result in
            switch result {
            case let .failure(error):
                self.state = .error(error: error)
            case let .success(note):
                self.state = .ready
                self.classifyImage(image: image, note: note)
            }
        } )
        self.imageEffectView.alpha = 1.0
        imageEffectView.image = image
        imageEffectView.frame = view.frame
        UIView.animate(withDuration: 0.3, animations: {
            self.imageEffectView.frame = self.imageEffectEndingReference
        }) { _ in
            UIView.animate(withDuration: 0.3, animations: {
                self.imageEffectView.alpha = 0.0
                self.imageEffectView.image = nil
            })
        }
    }
    
    func classifyImage(image: UIImage, note: LMNote) {
        guard let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue)), let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([self.classificationRequest(for: note, image: image)])
            } catch {
                return
            }
        }
    }
    
    func classificationRequest(for note: LMNote, image: UIImage) -> VNCoreMLRequest {
        do {
            let model = try VNCoreMLModel(for: ImageClassifier().model)
            
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, note: note, image: image, error: error)
            })
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }
    
    func processClassifications(for request: VNRequest, note: LMNote, image: UIImage, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                return
            }
            let classifications = results as! [VNClassificationObservation]
            if classifications.isEmpty {
                return
            } else {
                if let topClassification = classifications.first, topClassification.confidence > 0.7, topClassification.identifier != "other" {
                    note.isDocument = true
                    try? self.appContext.storage.saveContext()
                }
            }
        }
    }
}

extension LMCameraViewController {
    enum State {
        case root
        case loading(message: String)
        case takingPicture
        case pictureRecieved
        case error(error: Error)
        case ready
        case pause
    }
}
