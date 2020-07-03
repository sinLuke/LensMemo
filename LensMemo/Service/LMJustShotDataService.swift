//
//  LMJustShotDataService.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-02.
//

import UIKit

struct LMJustShotDataService {
    static let shared = LMJustShotDataService()
    var images: [ImagesJustShot] = []
    struct ImagesJustShot {
        var Image: UIImage
        var note: UUID
        var notebook: UUID
        var shotAt: Date
        var sticker: UUID
    }
}
