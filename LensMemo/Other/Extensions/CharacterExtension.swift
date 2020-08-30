//
//  CharacterExtension.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-08-22.
//

import Foundation

extension Character {
    var isEmoji: Bool {
        guard let firstScalar = unicodeScalars.first else { return false }
        return firstScalar.properties.isEmoji && firstScalar.value > 0x238C
        ||
        unicodeScalars.count > 1 && unicodeScalars.first?.properties.isEmoji ?? false
    }
}
