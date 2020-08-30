//
//  LMImageView.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-08-29.
//

import UIKit

class LMImageView: UIImageView {

    var originalImage: UIImage? {
        didSet {
            if !isDocument {
                image = originalImage
            } else {
                image = setupInverseFilter(originalImage)
            }
            
        }
    }
    
    var isDocument: Bool = false
    
    func setupInverseFilter(_ inputImage: UIImage?) -> UIImage? {
        let context = CIContext(options: nil)
        
        if let currentFilter = CIFilter(name: "CIColorInvert"), let originalImage = inputImage {
            let beginImage = CIImage(image: originalImage)
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
//            currentFilter.setValue(0.5, forKey: kCIInputIntensityKey)
            
            if let output = currentFilter.outputImage {
                if let cgimg = context.createCGImage(output, from: output.extent) {
                    return UIImage(cgImage: cgimg)
                }
            }
        }
        
        return originalImage
    }
    
    func setupScanedFilter(_ inputImage: UIImage?) -> UIImage? {
        let context = CIContext(options: nil)
        
        if let currentFilter = CIFilter(name: "CIDocumentEnhancer"), let originalImage = inputImage {
            let beginImage = CIImage(image: originalImage)
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
            //            currentFilter.setValue(0.5, forKey: kCIInputIntensityKey)
            
            if let output = currentFilter.outputImage {
                if let cgimg = context.createCGImage(output, from: output.extent) {
                    return UIImage(cgImage: cgimg)
                }
            }
        }
        
        return originalImage
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
    }
}
