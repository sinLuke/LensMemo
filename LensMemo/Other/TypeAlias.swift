//
//  TypeAlias.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-15.
//

import Foundation

typealias Completion = () -> ()
typealias CallBack<T> = (T) -> ()
typealias ResultAsync<T> = (Result<T, Error>) -> ()

func main(_ code: @escaping Completion) { DispatchQueue.main.async(execute: code) }
