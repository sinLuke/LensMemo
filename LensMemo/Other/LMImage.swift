//
//  LMImage.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-14.
//

import UIKit

class LMImage {
    enum Keys: String {
        case Images
        case fingerPrint
        case data
    }
    
    enum Quality: String, Comparable {
        static func < (lhs: LMImage.Quality, rhs: LMImage.Quality) -> Bool {
            switch rhs {
            case .original:
                return lhs != .original
            case .small:
                return false
            case .large:
                return lhs == .small
            }
        }
        
        case original = "0"
        case small = "1"
        case large = "2"
    }
}

