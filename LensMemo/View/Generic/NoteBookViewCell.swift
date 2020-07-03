//
//  NoteBookViewCell.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-01.
//

import Foundation

protocol Cell: class {
    associatedtype SomeEntity
    func configure(data: SomeEntity)
}
