//
//  ActTests.swift
//  ActTests
//
//  Created by Robin Goos on 24/10/15.
//  Copyright © 2015 Robin Goos. All rights reserved.
//

import XCTest
@testable import Act
class ActorTests: XCTestCase {
    
    struct Add : Message {
        let type = "Add"
        let value: Float
    }
    
    struct Subtract : Message {
        let type = "Subtract"
        let value: Float
    }
    
    struct Multiply : Message {
        let type = "Multiply"
        let value: Float
    }
    
    func calculatorReducer(state: Float, message: Message) -> Float {
        switch(message) {
        case let i as Add:
            return state + i.value
        case let i as Subtract:
            return state - i.value
        case let i as Multiply:
            return state * i.value
        default:
            return state
        }
    }
    
    var calculator: Actor<Float>!
    
    override func tearDown() {
        calculator = nil
    }
    
    func testMessagePassing() {
        let tester = TestTransformer(expected: [({
            let i = $0 as? Multiply; return i?.value == 3.0
        }, expectationWithDescription("The actor should receive a message to multiply.")),
        ({
            let i = $0 as? Add; return i?.value == 5.0
        }, expectationWithDescription("The actor should receive a message to add")),
        ({
            let i = $0 as? Subtract; return i?.value == 10.0
        }, expectationWithDescription("The actor should receive a message to subtract.")),
        ])
        
        calculator = Actor(initialState: 4.0, transformers: [tester.receive], reducer: calculatorReducer)
        
        calculator.send(Multiply(value: 3))
        calculator.send(Add(value: 5))
        calculator.send(Subtract(value: 10))
        waitForExpectationsWithTimeout(1, handler: nil)
        
        XCTAssert(calculator.state == 4 * 3 + 5 - 10, "The state should be updated by the actor's reducer after the messages have been handled.")
    }
    
    func testMessageCallbacks() {
        calculator = Actor(initialState: 4.0, transformers: [], reducer: calculatorReducer, callbackQueue: dispatch_queue_create("test", DISPATCH_QUEUE_SERIAL).queueable())
        
        let subtractExp = expectationWithDescription("The calculator should send a callback once a message has been handled.")
        calculator.send(Subtract(value: 2)) { state in
            if state == 2 {
                subtractExp.fulfill()
            }
        }
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}