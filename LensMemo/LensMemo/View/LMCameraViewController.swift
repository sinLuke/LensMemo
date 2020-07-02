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
    @IBOutlet weak var imageEffectEndingReferenceView: UIView!
    @IBOutlet weak var currentStatusMessageLabel: UILabel!
    @IBOutlet weak var shadowEffectView: UIView!
    
    @IBOutlet weak var stickerPickingView: UITableView!
    @IBOutlet weak var notebookPickingView: UITableView!
    
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
                switch self.state {
                case let .error(message):
                    let alert = LMAlertViewViewController.getInstance(icon: UIImage(systemName: "camera.fill"), color: .systemRed, title: "Camera Error", message: message, buttons: [
                        LMAlertViewViewController.Button(title: "Retry", backgroundColor: .label, onTap: { [weak self] in
                            self?.dismiss(animated: false, completion: {
                                self?.state = .root
                            })
                        }),
                        LMAlertViewViewController.Button(title: "Back to my notebook", backgroundColor: .label, onTap: { [weak self] in
                            // TODO
                            self?.dismiss(animated: false, completion: {
                                self?.state = .root
                            })
                        })
                    ])
                    alert.modalPresentationStyle = .overCurrentContext
                    self.present(alert, animated: false, completion: nil)
                    
                case .root:
                    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                        self?.viewModel.setUpCaptureSession()
                    }
                case let .loading(message):
                    self.currentStatusMessageLabel.text = message
                    self.currentStatusMessageLabel.isHidden = false
                case .takingPicture:
                    self.cameraEffectView.alpha = 1.0
                    UIView.animate(withDuration: 0.1) {
                        self.cameraEffectView.alpha = 0.0
                    }
                case let .pictureRecieved(_):
                    self.stickerPickingView.isHidden = false
                    self.notebookPickingView.isHidden = false
                case .ready:
                    self.takePictureButton.isHidden = false
                    self.takePictureImage.isHidden = false
                    self.stickerPickingView.isHidden = false
                    self.notebookPickingView.isHidden = false
                    return
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        state = .root
        takePictureButton.layer.cornerRadius = takePictureButton.bounds.width / 2
        takePictureButton.clipsToBounds = true
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        resetVideoOrientation()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
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
    
    static func getInstance() -> LMCameraViewController {
        return LMCameraViewController(nibName: String(describing: LMCameraViewController.self), bundle: nil)
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
            self.previewView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            self.previewView.layer.addSublayer(videoPreviewLayer)
            videoPreviewLayer.frame = self.previewView.bounds
            self.videoPreviewLayer = videoPreviewLayer
            self.state = .loading(message: "Starting Camera Session")
            self.viewModel.startCaptureSession()
            self.resetVideoOrientation()
        }
    }
    
    func sessionHasStarted() {
        state = .ready
    }
    
    func pictureDidTaken(data: Data) {
        self.state = .ready
        self.imageEffectView.alpha = 1.0
        let image = UIImage(data: data)
        imageEffectView.image = image
        imageEffectView.frame = view.frame
        UIView.animate(withDuration: 0.3, animations: {
            self.imageEffectView.frame = self.imageEffectEndingReferenceView.frame
        }) { _ in
            UIView.animate(withDuration: 0.3, animations: {
                self.imageEffectView.alpha = 0.0
                self.imageEffectView.image = nil
            })
        }
    }
    
    func resetVideoOrientation() {
        print(UIDevice.current.orientation == .landscapeLeft)
        if UIDevice.current.orientation == .landscapeLeft {
            videoPreviewLayer?.connection?.videoOrientation = .landscapeRight
        } else {
            videoPreviewLayer?.connection?.videoOrientation = .landscapeLeft
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
    }
}
