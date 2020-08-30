//
//  UIImageExtension.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-12.
//

import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

extension UIImage {
    var compactColor: Int64? {
        guard let inputImage = CIImage(image: self) else { return nil }
        if inputImage.extent.size.width > 6400 || inputImage.extent.size.height > 4200 {
            return Int64(129) + Int64(129)*256 + Int64(129)*256*256
        }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)
        
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        return Int64(bitmap[0]) + Int64(bitmap[1])*256 + Int64(bitmap[2])*256*256
    }
    
    public convenience init?(color: UIColor) {
        let rect = CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}
