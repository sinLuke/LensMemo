//
//  LMDispatchGroup.swift
//  LensMemo
//
//  Created by Luke Yin on 2020-07-15.
//

import UIKit

class LMDispatchGroup {
    let group: DispatchGroup = DispatchGroup()
    var error: Error?
    
    func enter() {
        group.enter()
    }
    
    func leave() {
        group.leave()
    }
    
    func wait() throws {
        group.wait()
        if let error = error {
            throw error
        }
    }
    
    func terminate(error: Error?) {
        self.error = error ?? NSError()
        group.leave()
    }
}
