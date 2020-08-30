//
//  LMMacMainDetailViewController.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-26.
//

#if targetEnvironment(macCatalyst)

import UIKit

class LMMacMainDetailViewController: LMViewController {
    
    @IBOutlet weak var noteListConstraint: NSLayoutConstraint!
    @IBOutlet weak var propertyInspectorConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var noteListLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var noteListTarilingToSuperLeading: NSLayoutConstraint!
    @IBOutlet weak var propertyInspectorTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var propertyInspectorAdjustmentView: UIView!
    @IBOutlet weak var noteListAdjustmentView: UIView!
    
    var noteListConstraintConstant: CGFloat = 300
    var propertyInspectorConstraintConstant: CGFloat = 300
    
    @IBOutlet weak var noteListView: UIView!
    @IBOutlet weak var propertyInspectorView: UIView!
    @IBOutlet weak var previewView: LMDisplayView!
    
    var previewLayout = LMMainViewPreviewLayout()
    var previewViewModel: LMImagePreviewViewModel!
    
    var lastUpdate = Date()
    
    var isNoteListVisible: Bool = true {
        didSet {
            noteListLeadingConstraint.isActive = isNoteListVisible
            noteListTarilingToSuperLeading.isActive = !isNoteListVisible
            UIView.animate(withDuration: 0.3) {
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
                self.previewView.adjustScrollableContent()
            }
        }
    }
    
    var isPropertyInspectorVisible: Bool = false {
        didSet {
            propertyInspectorTrailingConstraint.constant = isPropertyInspectorVisible ? 0 : (propertyInspectorConstraint.constant)
            
            UIView.animate(withDuration: 0.3) {
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
                self.previewView.setTrailingAdditionalInset(inset: self.propertyInspectorConstraint.constant - self.propertyInspectorTrailingConstraint.constant)
            }
        }
    }
    
    override func viewDidLoad() {
        addSubViewConreoller(appContext.mainViewMenuNoteListViewController, in: noteListView)
        addSubViewConreoller(appContext.imageDetailViewController, in: propertyInspectorView)
        previewView.configure(dataSource: self, delegate: self)
        previewLayout.viewModel = previewViewModel
        
        let noteListGesture = UIPanGestureRecognizer(target: self, action: #selector(noteListGestureCallback))
        let noteListHoverGesture = UIHoverGestureRecognizer(target: self, action: #selector(noteListViewHoverCallback))
        noteListAdjustmentView.addGestureRecognizer(noteListGesture)
        noteListAdjustmentView.addGestureRecognizer(noteListHoverGesture)
        let propertyInspectorGesture = UIPanGestureRecognizer(target: self, action: #selector(propertyInspectorGestureCallback))
        let propertyInspectorHoverGesture = UIHoverGestureRecognizer(target: self, action: #selector(propertyInspectorHoverCallback))
        propertyInspectorAdjustmentView.addGestureRecognizer(propertyInspectorGesture)
        propertyInspectorAdjustmentView.addGestureRecognizer(propertyInspectorHoverGesture)
    }
    
    
    @objc func noteListGestureCallback(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            noteListConstraintConstant = noteListConstraint.constant
        case .changed:
            let maximumAllowed = max(0, propertyInspectorView.frame.minX - (noteListView.frame.minX + noteListConstraintConstant) - 100)
            let xOffset = min(maximumAllowed, sender.translation(in: self.view).x)
            noteListConstraint.constant = max(300, noteListConstraintConstant + xOffset)
            view.setNeedsLayout()
            previewView.adjustScrollableContent()
        default: break
        }
    }
    
    @objc func propertyInspectorGestureCallback(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            propertyInspectorConstraintConstant = propertyInspectorConstraint.constant
        case .changed:
            let maximumAllowed = max(0, (propertyInspectorView.frame.maxX - propertyInspectorConstraintConstant) - noteListView.frame.maxX - 100)
            let xOffset = max(-maximumAllowed, sender.translation(in: self.view).x)
            propertyInspectorConstraint.constant = max(300, propertyInspectorConstraintConstant - xOffset)
            view.setNeedsLayout()
            previewView.setTrailingAdditionalInset(inset: propertyInspectorConstraint.constant)
        default: break
        }
    }
    
    @objc func noteListViewHoverCallback(_ sender: UIHoverGestureRecognizer) {
        let location = sender.location(in: self.view).x
        let leftAdjustable = location - noteListView.frame.minX > 308
        let rightAdjustable = propertyInspectorView.frame.minX - location > 108
        switch sender.state {
        case .began:
            setCursor(left: leftAdjustable, right: rightAdjustable)
        case .changed:
            setCursor(left: leftAdjustable, right: rightAdjustable)
        case .ended:
            setCursor(left: false, right: false)
        default:
            setCursor(left: false, right: false)
        }
    }
    
    @objc func propertyInspectorHoverCallback(_ sender: UIHoverGestureRecognizer) {
        let location = sender.location(in: self.view).x
        let leftAdjustable = location - noteListView.frame.maxX > 108
        let rightAdjustable = propertyInspectorView.frame.maxX - location > 308
        switch sender.state {
        case .began:
            setCursor(left: leftAdjustable, right: rightAdjustable)
        case .changed:
            setCursor(left: leftAdjustable, right: rightAdjustable)
        case .ended:
            setCursor(left: false, right: false)
        default:
            setCursor(left: false, right: false)
        }
    }
    
    func setCursor(left: Bool, right: Bool) {
        if left, !right {
            NSCursor.resizeLeft.set()
        } else if !left, right {
            NSCursor.resizeRight.set()
        } else if left, right {
            NSCursor.resizeLeftRight.set()
        } else {
            NSCursor.arrow.set()
        }
    }
    
    static func getInstance(appContext: LMAppContext) -> LMMacMainDetailViewController {
        let mainDetailViewController = LMMacMainDetailViewController(nibName: String(describing: LMMacMainDetailViewController.self), bundle: nil)
        mainDetailViewController.appContext = appContext
        mainDetailViewController.previewViewModel = LMImagePreviewViewModel(appContext: appContext)
        return mainDetailViewController
    }
    
    func focusPreview(notes: [LMNote]) {
        lastUpdate = Date()
        previewViewModel.build(notes: notes)
        previewView.reloadData()
        previewView.resetZoomLevel(animated: false)
    }
    
    func selectedNote(note: LMNote) {
        if let index = previewViewModel.notes.firstIndex(of: note) {
            previewView.scrollTo(item: index)
        }
    }
}

extension LMMacMainDetailViewController: LMDisplayViewDataSource {
    func numberOfImages() -> Int {
        return previewViewModel.notes.count
    }
    
    func displayView(_ displayView: LMDisplayView, sizeOfImageAt index: Int) -> CGSize {
        return CGSize(width: CGFloat(previewViewModel.notes[index].imageWidth), height: CGFloat(previewViewModel.notes[index].imageHeight))
    }
    
    func displayView(_ displayView: LMDisplayView, imageAt index: Int, quality: LMImage.Quality?) -> UIImage? {
        let lastValidUpdate = lastUpdate
        if let image = appContext.imageService.getImage(for: previewViewModel.notes[index], quality: quality ?? .original, onlyFromLocal: false, completion: { (result) in
            result.see(ifSuccess: { (_) in
                DispatchQueue.main.async {
                    if lastValidUpdate == self.lastUpdate {
                        displayView.loadImage(at: index)
                    }
                }
            }) { (_) in
                return
            }
        }) {
            return image
        } else {
            return nil
        }
    }
    
    func displayView(_ displayView: LMDisplayView, compactColorOfImageAt index: Int) -> UIColor {
        return UIColor(compactColor: previewViewModel.notes[index].compactColor)
    }
}

extension LMMacMainDetailViewController: LMDisplayViewDelegate {
    func shouldUseTimmer() -> Bool {
        true
    }
    
    func displayViewDidScrollTo(_ index: Int) {
        return
    }
    
    func displayViewDidRecievedTap(_ index: Int) {
        appContext.selectedNote(note: previewViewModel.notes[index])
    }
    
    func displayViewDidRecievedUserInteractive() {

    }
    
    func displayViewDidFocusOnNote(_ index: Int) {
        previewViewModel.notes[index].lastViewed = Date()
        try? appContext.storage.saveContext()
    }
    
    func displayViewShowNoteDetail(_ index: Int) {
        return
    }
}
#endif
