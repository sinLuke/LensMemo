////
////  LMPhotoPreparingTableViewCell.swift
////  LensMemo
////
////  Created by Luke Yin on 2020-09-01.
////
//
//import UIKit
//
//class LMPhotoPreparingTableViewCell: UITableViewCell {
//
//    @IBOutlet weak var leadingImageView: UIImageView!
//    @IBOutlet weak var mainLabel: UILabel!
//    @IBOutlet weak var secondaryLabel: UILabel!
//    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
//    @IBOutlet weak var secondaryImage: UIImageView!
//    
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        selectionStyle = .none
//        
//        leadingImageView.backgroundColor = .systemFill
//        leadingImageView.layer.cornerRadius = 4
//        leadingImageView.image = nil
//        
//        activityIndicator.stopAnimating()
//        activityIndicator.isHidden = true
//        secondaryImage.isHidden = true
//    }
//    
//    func update(data: LMPhotoPreparingViewController.SubTask) {
//        awakeFromNib()
//        leadingImageView.image = data.image
//        mainLabel.text = data.title
//        secondaryLabel.text = data.statusDescription
//        switch data.status {
//        case .finish:
//            secondaryImage.isHidden = false
//            secondaryImage.image = UIImage(systemName: "checkmark.circle.fill")
//            secondaryImage.tintColor = .systemGreen
//        case .error:
//            secondaryImage.isHidden = false
//            secondaryImage.image = UIImage(systemName: "xmark.circle.fill")
//            secondaryImage.tintColor = .systemRed
//        case .queue:
//            secondaryImage.isHidden = false
//            secondaryImage.image = UIImage(systemName: "clock.fill")
//            secondaryImage.tintColor = .systemGray
//        case .loading:
//            activityIndicator.startAnimating()
//            activityIndicator.isHidden = false
//        }
//    }
//    
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        awakeFromNib()
//    }
//}
