//
//  LMCameraViewController.swift
//  LensMemo-iOS
//
//  Created by Luke Yin on 2020-07-01.
//

import UIKit
import AVFoundation

class LMCameraViewController: LMViewController {
    // MARK: - IBOutlet
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var takePictureButton: UIButton!
    @IBOutlet weak var takePictureImage: UIImageView!
    @IBOutlet weak var cameraEffectView: UIView!
    @IBOutlet weak var imageEffectView: UIImageView!
    @IBOutlet weak var currentStatusMessageLabel: UILabel!
    @IBOutlet weak var shadowEffectView: UIView!
    
    @IBOutlet weak var stickerPickingView: UITableView!
    @IBOutlet weak var notebookPickingView: UITableView!
    
    var imageEffectEndingReference: CGRect = CGRect(x: 0, y: 0, width: 100, height: 100)
    var cameraNotebookDelegate: LMCameraViewNotebookTableViewDelegate?
    var cameraStickerDelegate: LMCameraViewStickerTableViewDelegate?
    
    // MARK: - Property
    
    var viewModel = LMCameraViewModel()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
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
                case let .error(message):
                    let alertData = LMAlertViewViewController.Data(
                        allowDismiss: false,
                        icon: UIImage(systemName: "camera.fill"),
                        color: .systemRed,
                        title: "Camera Error",
                        messages: ["Error message: \(message)"],
                        primaryButton: LMAlertViewViewController.Button(title: "Retry", onTap: { [weak self] in
                            self?.dismiss(animated: false, completion: {
                                self?.state = .root
                            })
                        }),
                        secondaryButton: LMAlertViewViewController.Button(title: "Back to my notebook", onTap: { [weak self] in
                            // TODO
                            self?.dismiss(animated: false, completion: {
                                self?.state = .root
                            })
                        }))
                    let alert = LMAlertViewViewController.getInstance(data: alertData)
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
                case let .pictureRecieved(image):
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
        shadowEffectView.layer.shadowColor = UIColor.black.cgColor
        shadowEffectView.layer.shadowOffset = CGSize(width: 0, height: 0)
        shadowEffectView.layer.shadowRadius = 16
        shadowEffectView.layer.shadowOpacity = 0.6
        
        do {
            cameraStickerDelegate = try LMCameraViewStickerTableViewDelegate(tableView: stickerPickingView, appContext: appContext)
            cameraNotebookDelegate = try LMCameraViewNotebookTableViewDelegate(tableView: notebookPickingView, appContext: appContext)
        } catch (let error) {
            state = .error(message: "Error: loading data \(error.localizedDescription)")
        }
        
        stickerPickingView.delegate = cameraStickerDelegate
        stickerPickingView.dataSource = cameraStickerDelegate
        
        notebookPickingView.delegate = cameraNotebookDelegate
        notebookPickingView.dataSource = cameraNotebookDelegate
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
        deviceDidRotated()
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
    
    func deviceDidRotated() {
        if isViewLoaded {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                if UIDevice.current.orientation == .landscapeRight {
                    self.shadowEffectView.transform = .identity
                }
                if UIDevice.current.orientation == .landscapeLeft {
                    self.shadowEffectView.transform = CGAffineTransform.identity.rotated(by: .pi)
                }
            }, completion: nil)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeLeft
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
    
    static func getInstance(appContext: LMAppContext) -> LMCameraViewController {
        let cameraViewController = LMCameraViewController(nibName: String(describing: LMCameraViewController.self), bundle: nil)
        cameraViewController.appContext = appContext
        return cameraViewController
    }
}

extension LMCameraViewController: LMCameraViewModelDelegate {
    func showError(message: String) {
        state = .error(message: message)
    }
    
    func sessionIsReady(session: AVCaptureSession) {
        DispatchQueue.main.async {
            let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
            videoPreviewLayer.videoGravity = .resizeAspectFill
            videoPreviewLayer.connection?.videoOrientation = .landscapeLeft
            self.previewView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            self.previewView.layer.addSublayer(videoPreviewLayer)
            videoPreviewLayer.frame = self.previewView.bounds
            self.videoPreviewLayer = videoPreviewLayer
            self.state = .loading(message: "Starting Camera Session")
            self.viewModel.startCaptureSession()
        }
    }
    
    func sessionHasStarted() {
        state = .ready
    }
    
    func pictureDidTaken(data: Data) {
        self.state = .pictureRecieved(imageData: data)
        self.appContext.noteService.addNote(name: "New note", message: "", image: UIImage(data: data), stickers: [self.appContext.state.selectedSticker].compactMap { $0 } )
        self.imageEffectView.alpha = 1.0
        let image = UIImage(data: data)
        imageEffectView.image = image
        imageEffectView.frame = view.frame
        UIView.animate(withDuration: 0.3, animations: {
            self.imageEffectView.frame = self.imageEffectEndingReference
        }) { _ in
            UIView.animate(withDuration: 0.3, animations: {
                self.imageEffectView.alpha = 0.0
                self.imageEffectView.image = nil
                self.state = .ready
            })
        }
    }
}

extension LMCameraViewController {
    enum State {
        case root
        case loading(message: String)
        case takingPicture
        case pictureRecieved(imageData: Data)
        case error(message: String)
        case ready
        case pause
    }
}
