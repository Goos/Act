//
//  ObservableActorTests.swift
//  Act
//
//  Created by Robin Goos on 24/10/15.
//  Copyright © 2015 Robin Goos. All rights reserved.
//

import XCTest
@testable import Act

enum TransactionType {
    case Withdrawal
    case Deposit
}

struct Transaction : Message, Equatable {
    let type = "Transaction"
    let transactionType: TransactionType
    let amount: Float
}

func ==(lhs: Transaction, rhs: Transaction) -> Bool {
    return lhs.transactionType == rhs.transactionType && lhs.amount == rhs.amount
}

struct BankState : Equatable {
    let transactions: [Transaction]
    let balance: Float
}

func ==(lhs: BankState, rhs: BankState) -> Bool {
    return lhs.transactions == rhs.transactions && lhs.balance == rhs.balance
}

class ObservableActorTests: XCTestCase {
    var bank: ObservableActor<BankState>!
    
    func testObserving() {
        let initialState = BankState(transactions: [], balance: 0.0)
        let queue = dispatch_queue_create("test", DISPATCH_QUEUE_SERIAL).queueable()
        
        bank = ObservableActor(initialState: initialState, transformers: [], reducer: { (state, message) in
            if let t = message as? Transaction {
                let transactions = [state.transactions, [t]].flatMap { $0 }
                if t.transactionType == .Deposit {
                    return BankState(transactions: transactions, balance: state.balance + t.amount)
                } else if (t.transactionType == .Withdrawal) {
                    return BankState(transactions: transactions, balance: state.balance - t.amount)
                }
            }
            
            return state
        }, callbackQueue: queue)
        
        let depositExp = expectationWithDescription("The actor should notify its subscribers of its updated state after a message changes it.")
        let withdrawalExp = expectationWithDescription("The actor should notify its subscribers of its updated state after a message changes it.")
        
        var i = 0
        bank.observe { state in
            if i == 0 && state.balance == 100 {
                depositExp.fulfill()
            } else if i == 1 && state.balance == 50 {
                withdrawalExp.fulfill()
            }
            i++
        }
        
        bank.send(Transaction(transactionType: .Deposit, amount: 100))
        bank.send(Transaction(transactionType: .Withdrawal, amount: 50))
        
        waitForExpectationsWithTimeout(1, handler: nil)
    }
}