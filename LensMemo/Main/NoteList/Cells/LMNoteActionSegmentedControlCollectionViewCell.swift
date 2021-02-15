//
//  LMNoteActionSegmentedControlCollectionViewCell.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-08-30.
//

import UIKit

class LMNoteActionSegmentedControlCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    var callBack: (Int) -> () = { _ in }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configure(options: [String], seletingIndex: Int, callBack: @escaping (Int) -> ()) {
        segmentedControl.removeAllSegments()
        options.indices.forEach { (id) in
            segmentedControl.insertSegment(withTitle: options[id], at: id, animated: false)
        }
        segmentedControl.selectedSegmentIndex = seletingIndex
        self.callBack = callBack
    }
    
    @IBAction func valueChanged(_ sender: Any) {
        guard let control = sender as? UISegmentedControl, control === self.segmentedControl else {
            return
        }
        callBack(control.selectedSegmentIndex)
    }
}
