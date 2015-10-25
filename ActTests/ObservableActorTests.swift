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
    
    func testSubscribing() {
        bank = ObservableActor(initialState: BankState(transactions: [], balance: 0.0), interactors: [], reducer: { (state, message) in
            if let t = message as? Transaction {
                let transactions = [state.transactions, [t]].flatMap { $0 }
                if t.transactionType == .Deposit {
                    return BankState(transactions: transactions, balance: state.balance + t.amount)
                } else if (t.transactionType == .Withdrawal) {
                    return BankState(transactions: transactions, balance: state.balance - t.amount)
                }
            }
            
            return state
        }, mainQueue: dispatch_queue_create("test", DISPATCH_QUEUE_SERIAL).queueable())
        
        let depositExp = expectationWithDescription("The actor should notify its subscribers of its updated balance after a deposit.")
        let withdrawalExp = expectationWithDescription("The actor should notify its subscribers of its updated balance after a withdrawal.")
        
        var i = 0
        bank.subscribe { state in
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