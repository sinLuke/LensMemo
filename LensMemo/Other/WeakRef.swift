//
//  WeakRef.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-04.
//

import Foundation

class Weak<T> where T: AnyObject {

    private(set) weak var value: T?

    init(_ value: T?) {
        self.value = value
    }
}
