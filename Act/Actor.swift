//
//  Actor.swift
//  Act
//
//  Created by Robin Goos on 24/10/15.
//  Copyright © 2015 Robin Goos. All rights reserved.
//

import Foundation

public protocol Message {
    var type: String { get }
}

public class Actor<T> {
    public typealias Interactor = (Actor<T>, Message, (Message) -> ()) -> ()
    public typealias Reducer = (T, Message) -> T
    
    public var state: T {
        return _state
    }
    
    private var _state: T
    
    public var interactors: [Interactor] = []
    public var reducer: Reducer
    
    private var backgroundQueue: Queueable
    private var mainQueue: Queueable

    public init(initialState: T, interactors: [Interactor], reducer: Reducer, mainQueue: Queueable? = nil, backgroundQueue: Queueable? = nil) {
        self._state = initialState
        self.interactors = interactors
        self.reducer = reducer
        self.mainQueue = mainQueue ?? dispatch_get_main_queue().queueable()
        self.backgroundQueue = backgroundQueue ?? dispatch_queue_create("com.act.actor", DISPATCH_QUEUE_SERIAL).queueable()
    }
    
    public func send(message: Message, completion: ((T) -> ())? = nil) {
        backgroundQueue.enqueue {
            if self.interactors.count > 0 {
                var gen = self.interactors.generate()
                
                func passOn(message: Message) {
                    if let next = gen.next() {
                        self.backgroundQueue.enqueue {
                            next(self, message, passOn)
                        }
                    } else {
                        self.backgroundQueue.enqueue {
                            self._state = self.reducer(self.state, message)
                            if let comp = completion {
                                let state = self.state
                                self.mainQueue.enqueue { comp(state) }
                            }
                        }
                    }
                }
                
                passOn(message)
            } else {
                self._state = self.reducer(self.state, message)
                if let comp = completion {
                    let state = self.state
                    self.mainQueue.enqueue { comp(state) }
                }
            }
        }
    }
}

public class ObservableActor<T: Equatable> : Actor<T> {
    private var subscribers: [Subscriber<T>] = []
    
    override private var _state: T {
        didSet {
            if (oldValue != state) {
                notifyChange()
            }
        }
    }
    
    private func notifyChange() {
        let state = self.state
        mainQueue.enqueue {
            for subscriber in self.subscribers {
                subscriber.closure(state)
            }
        }
    }
    
    public func subscribe(subscriber: (T) -> ()) -> (() -> ())! {
        let boxed = Subscriber(closure: subscriber)
        subscribers.append(boxed)
        return {
            if let index = self.subscribers.indexOf(boxed) {
                self.subscribers.removeAtIndex(index)
            }
        }
    }
    
    override init(initialState: T, interactors: [Interactor], reducer: Reducer, mainQueue: Queueable? = nil, backgroundQueue: Queueable? = nil) {
        super.init(initialState: initialState, interactors: interactors, reducer: reducer, mainQueue: mainQueue, backgroundQueue: backgroundQueue)
    }
}

private final class Subscriber<T: Equatable> : Equatable {
    let closure: (T) -> ()
    init(closure: (T) -> ()) {
        self.closure = closure
    }
}

private func ==<T>(lhs: Subscriber<T>, rhs: Subscriber<T>) -> Bool {
    return lhs === rhs
}