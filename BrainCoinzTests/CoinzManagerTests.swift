//
//  CoinzManagerTests.swift
//  BrainCoinzTests
//
//  Created on 2025-01-14.
//

import XCTest
@testable import BrainCoinz

final class CoinzManagerTests: XCTestCase {
    
    var coinzManager: CoinzManager!
    
    override func setUpWithError() throws {
        coinzManager = CoinzManager()
    }
    
    override func tearDownWithError() throws {
        coinzManager = nil
    }
    
    func testInitialState() throws {
        XCTAssertEqual(coinzManager.totalCoinz, 0)
        XCTAssertEqual(coinzManager.todayCoinz, 0)
        XCTAssertEqual(coinzManager.carryoverCoinz, 0)
    }
    
    func testAddCoinz() throws {
        coinzManager.addCoinz(10)
        XCTAssertEqual(coinzManager.totalCoinz, 10)
        XCTAssertEqual(coinzManager.todayCoinz, 10)
        XCTAssertEqual(coinzManager.carryoverCoinz, 0)
    }
    
    func testSpendCoinz() throws {
        coinzManager.addCoinz(20)
        XCTAssertTrue(coinzManager.spendCoinz(5))
        XCTAssertEqual(coinzManager.totalCoinz, 15)
        XCTAssertEqual(coinzManager.todayCoinz, 15)
        XCTAssertEqual(coinzManager.carryoverCoinz, 0)
        
        // Test overspending
        XCTAssertFalse(coinzManager.spendCoinz(20))
        XCTAssertEqual(coinzManager.totalCoinz, 15) // Should remain unchanged
    }
    
    func testCarryoverCoinz() throws {
        coinzManager.addCoinz(10)
        coinzManager.simulateDayEnd() // This would normally be called at midnight
        
        // Add more coinz the next day
        coinzManager.addCoinz(5)
        XCTAssertEqual(coinzManager.totalCoinz, 15)
        XCTAssertEqual(coinzManager.todayCoinz, 5)
        XCTAssertEqual(coinzManager.carryoverCoinz, 10)
    }
}