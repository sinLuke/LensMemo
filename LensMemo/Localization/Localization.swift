//
//  Localization.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-08-22.
//

import Foundation

prefix operator ~

prefix func ~(value: String) -> String {
    return NSLocalizedString(value, comment: value)
}

func l(_ format: String, _ arguments: CVarArg ...) -> String {
    return String(format: ~format, arguments: arguments)
}

