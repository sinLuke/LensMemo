//
//  ResultExtension.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-15.
//

import Foundation

extension Result {
    func see(ifSuccess: (Success) -> (), ifNot: (Failure) -> ()) {
        switch self {
        case let .failure(error):
            ifNot(error)
        case let .success(success):
            ifSuccess(success)
        }
    }
}
