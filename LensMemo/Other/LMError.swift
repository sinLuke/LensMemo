//
//  LMError.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-11.
//

import Foundation

enum LMError: Error {
    case errorWhenSaveImage
    case errorWhenLoadImage
    case cameraError
    case iCloudImageError
    case errorWhenReadingImageData
    case errorLocalImageFileNotExist
    case defaultError
}
