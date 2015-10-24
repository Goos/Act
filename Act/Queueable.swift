//
//  Queueable.swift
//  Act
//
//  Created by Robin Goos on 24/10/15.
//  Copyright © 2015 Robin Goos. All rights reserved.
//

import Foundation

public protocol Queueable {
    func enqueue(task: () -> ())
}

extension Queueable {
    func enqueue(task: (() -> ())?) {
        if let t = task {
            enqueue(t)
        }
    }
}

extension NSRunLoop : Queueable {
    public func enqueue(task: () -> ()) {
        CFRunLoopPerformBlock(getCFRunLoop(), NSDefaultRunLoopMode, task)
    }
}

extension NSOperationQueue : Queueable {
    public func enqueue(task: () -> ()) {
        addOperationWithBlock(task)
    }
}

// A workaround due to the dispatch queue protocol not being extendable to conform to protocols.
public final class DispatchQueueable : Queueable {
    let dispatchQueue: dispatch_queue_t
    
    init(_ queue: dispatch_queue_t) {
        dispatchQueue = queue
    }
    
    public func enqueue(task: () -> ()) {
        dispatch_async(dispatchQueue, task)
    }
}

extension dispatch_queue_t {
    public func queueable() -> DispatchQueueable {
        return DispatchQueueable(self)
    }
}