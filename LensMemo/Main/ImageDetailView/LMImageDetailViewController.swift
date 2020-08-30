//
//  LMImageDetailViewController.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-11.
//

import UIKit

class LMImageDetailViewController: LMViewController {
    
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    weak var note: LMNote? {
        didSet {
            guard isViewLoaded else { return }
            emptyLabel.isHidden = note != nil
            scrollView.isHidden = note == nil
        }
    }
    
    @IBOutlet weak var noteImagePreview: UIImageView!
    @IBOutlet weak var notePrimaryLabel: UILabel!
    @IBOutlet weak var documentLabelContainer: UIView!
    @IBOutlet weak var documentLabelBackground: UIView!
    @IBOutlet weak var documentLabel: UILabel!
    @IBOutlet weak var noteTitleTextField: UITextField!
    @IBOutlet weak var noteDescriptionTitle: UILabel!
    @IBOutlet weak var noteDescriptionTextField: UITextView!
    @IBOutlet weak var stickerPickerTitle: UILabel!
    @IBOutlet weak var stickerPickerCollectionView: UICollectionView!
    @IBOutlet weak var stackLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var stackTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    @IBOutlet weak var imageWidth: NSLayoutConstraint!
    
    @IBOutlet weak var topBackground: UIView!
    
    var stickerViewModel: LMStickerSelectionViewModel?
    var stickerLayout = LMStickerSelectionLayout()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emptyLabel.text = "Select a note"
        noteTitleTextField.delegate = self
        noteDescriptionTextField.delegate = self
        #if !targetEnvironment(macCatalyst)
        view.backgroundColor = .systemBackground
        stackLeadingConstraint.constant = 16
        stackTrailingConstraint.constant = 16
        scrollView.contentInset.top = 16
        topBackground.backgroundColor = .secondarySystemBackground
        #else
        stackLeadingConstraint.constant = 8
        stackTrailingConstraint.constant = 8
        scrollView.contentInset.top = 8
        #endif
        
        noteDescriptionTextField.layer.cornerRadius = 4
        stickerPickerCollectionView.layer.cornerRadius = 4
        
        noteImagePreview.transform = CGAffineTransform(rotationAngle: -0.06)
        
        noteImagePreview.layer.borderWidth = 4
        noteImagePreview.layer.borderColor = UIColor.white.cgColor
        noteImagePreview.layer.shadowColor = UIColor.black.cgColor
        noteImagePreview.layer.shadowOffset = CGSize(width: 0, height: 4)
        noteImagePreview.layer.shadowRadius = 8
        noteImagePreview.layer.shadowOpacity = 0.4
        noteImagePreview.clipsToBounds = false
    }

    static func getInstance(appContext: LMAppContext) -> LMImageDetailViewController {
        let imageDetailViewController = LMImageDetailViewController(nibName: String(describing: LMImageDetailViewController.self), bundle: nil)
        imageDetailViewController.appContext = appContext
        return imageDetailViewController
    }
    
    func update(note: LMNote?) {
        self.resignFirstResponder()
        
        DispatchQueue.main.async {
            self.configure(note: note)
        }
    }

    func configure(note: LMNote?) {
        self.note = note
        
        guard isViewLoaded else { return }
        
        if let note = note {
            stickerPickerCollectionView.register(UINib(nibName: String(describing: LMStickerSelectionCollectionViewCell.self), bundle: nil), forCellWithReuseIdentifier: String(describing: LMStickerSelectionCollectionViewCell.self))
            stickerViewModel = LMStickerSelectionViewModel(appContext: appContext, note: note)
            stickerPickerCollectionView.delegate = stickerViewModel
            stickerPickerCollectionView.dataSource = stickerViewModel
            stickerPickerCollectionView.collectionViewLayout = stickerLayout.getLayout()
            stickerPickerCollectionView.reloadData()
            
            stickerPickerCollectionView.isHidden = stickerViewModel?.stickers.count == 0
            stickerPickerTitle.isHidden = stickerViewModel?.stickers.count == 0
        }
        
        if let noteImageHeight = note?.imageHeight, let noteImageWidth = note?.imageWidth, noteImageWidth != 0, noteImageHeight != 0 {
            let scale = CGFloat(max(noteImageWidth, noteImageHeight)) / 80
            imageHeight.constant = CGFloat(noteImageHeight) / scale
            imageWidth.constant = CGFloat(noteImageWidth) / scale
        }
        
        if let note = self.note {
            noteImagePreview.image = appContext.imageService.getImage(for: note, quality: .small, onlyFromLocal: false, completion: { [weak self] (image) in
                if note == self?.note {
                    self?.noteImagePreview.image = try? image.get()
                }
            })
        }
        
        documentLabel.text = "Document"
        documentLabelContainer.isHidden = !(note?.isDocument == true)
        documentLabelBackground.layer.cornerRadius = 4
        
        if let date = note?.created {
            let createdDateFormatter = NoteDateFomatter()
            notePrimaryLabel.text = "\(createdDateFormatter.string(from: date))"
        } else {
            notePrimaryLabel.text = "Unknown image"
        }
        
        if note?.message == "" || note?.message == nil {
            noteTitleTextField.text = nil
        } else {
            noteTitleTextField.text = note?.name
        }
        
        noteTitleTextField.placeholder = "Untitled Note"
        
        noteDescriptionTitle.text = "Note"
        if note?.message == "" || note?.message == nil {
            noteDescriptionTextField.text = "Add some notes here"
        } else {
            noteDescriptionTextField.text = note?.message
        }
        
        
        
        stickerPickerTitle.text = "Sticker"
    }
    
    override func appStateDidSet() {
        update(note: appContext.state.selectedNote)
    }
    @IBAction func addReminder(_ sender: Any) {
        guard let note = appContext.state.selectedNote else {
            return
        }
        LMEventService.shared.createReminder(for: note, appContext: appContext)
    }
}

extension LMImageDetailViewController: UITextFieldDelegate {
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        do {
            note?.name = textField.text
            try appContext.storage.saveContext()
        } catch (let error) {
            let alert = LMAlertViewViewController.getInstance(error: error)
            present(alert, animated: false, completion: nil)
        }
        
        return true
    }
}

extension LMImageDetailViewController: UITextViewDelegate {
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        do {
            note?.message = textView.text
            try appContext.storage.saveContext()
        } catch (let error) {
            let alert = LMAlertViewViewController.getInstance(error: error)
            present(alert, animated: false, completion: nil)
        }
        
        return true
    }
}
