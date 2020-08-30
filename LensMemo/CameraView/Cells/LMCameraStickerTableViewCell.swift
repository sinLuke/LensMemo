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
        circleBorder.strokeColor = UIColor.white.cgColor
        let dashLength: NSNumber = NSNumber(value: ((32 * Float.pi) / 32))
        circleBorder.lineDashPattern = [dashLength, dashLength]
        circleBorder.frame = CGRect(x: 16, y: 16, width: 32, height: 32)
        circleBorder.fillColor = nil
        circleBorder.path = UIBezierPath(ovalIn: circleBorder.bounds).cgPath
        circleBorder.lineWidth = 2
        selectionView.layer.cornerRadius = 8
        layer.addSublayer(circleBorder)
    }

    func configure(data: LMSticker?, appContext: LMAppContext) {
        isShowingSelected = appContext.state.applyingSticker == data
        selectionView.isHidden = !isShowingSelected
        if let data = data {
            circleBorder.isHidden = true
            label.isHidden = false
            label.text = String(data.name?.first ?? "?")
            print(String(data.name?.first ?? "?"))
        } else {
            circleBorder.isHidden = false
            label.isHidden = true
        }
    }
}
