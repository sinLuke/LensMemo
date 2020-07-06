//
//  LMCameraStickerTableViewCell.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-05.
//

import UIKit

class LMCameraStickerTableViewCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    var circleBorder: CAShapeLayer!
    var isShowingSelected = false
    @IBOutlet weak var selectionView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        circleBorder = CAShapeLayer()
        circleBorder.strokeColor = UIColor.secondaryLabel.cgColor
        let dashLength: NSNumber = NSNumber(value: ((32 * Float.pi) / 12))
        print(dashLength)
        circleBorder.lineDashPattern = [dashLength, dashLength]
        circleBorder.frame = CGRect(x: 16, y: 16, width: 32, height: 32)
        circleBorder.fillColor = nil
        circleBorder.path = UIBezierPath(ovalIn: circleBorder.bounds).cgPath
        layer.addSublayer(circleBorder)
        
        selectionView.layer.cornerRadius = 24
        selectionView.clipsToBounds = true
        selectionView.layer.borderWidth = 2
        selectionView.layer.borderColor = UIColor.secondaryLabel.cgColor
    }
    
    func configure(data: LMSticker?, appContext: LMAppContext) {
        isShowingSelected = appContext.state.selectedNotebook?.id == data?.id
        selectionView.isHidden = !isShowingSelected
        if let data = data {
            circleBorder.isHidden = true
            label.text = String(data.name?.first ?? "?")
        } else {
            circleBorder.isHidden = true
            label.text = "✅"
        }
    }
}
