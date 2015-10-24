//
//  TestInteractor.swift
//  Act
//
//  Created by Robin Goos on 24/10/15.
//  Copyright © 2015 Robin Goos. All rights reserved.
//

import XCTest
@testable import Act

final class TestInteractor {
    typealias Comparator = (Intent) -> Bool
    typealias Expectation = (Comparator, XCTestExpectation)
    var expectations: [Expectation]
    let backgroundQueue = dispatch_queue_create("expectations", DISPATCH_QUEUE_SERIAL)
    
    init(expected: [Expectation]) {
        expectations = expected
    }
    
    func receive<T>(actor: Actor<T>, intent: Intent, next: (Intent) -> ()) {
        let exp = expectations.removeFirst()
        let comp = exp.0
        if comp(intent) {
            exp.1.fulfill()
        }
        next(intent)
    }
}