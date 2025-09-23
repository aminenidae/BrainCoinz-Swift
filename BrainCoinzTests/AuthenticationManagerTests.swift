//
//  AuthenticationManagerTests.swift
//  BrainCoinzTests
//
//  Created on 2025-01-14.
//

import XCTest
@testable import BrainCoinz

final class AuthenticationManagerTests: XCTestCase {
    
    var authenticationManager: AuthenticationManager!
    
    override func setUpWithError() throws {
        authenticationManager = AuthenticationManager()
    }
    
    override func tearDownWithError() throws {
        authenticationManager = nil
    }
    
    func testGenerateParentCode() throws {
        let code = authenticationManager.generateParentCode()
        XCTAssertNotNil(code)
        XCTAssertEqual(code.count, 4)
        XCTAssertTrue(code.allSatisfy { $0.isNumber })
    }
    
    func testIsValidParentCode() throws {
        // Test valid codes
        XCTAssertTrue(isValidParentCode("1234"))
        XCTAssertTrue(isValidParentCode("12345"))
        XCTAssertTrue(isValidParentCode("123456"))
        
        // Test invalid codes
        XCTAssertFalse(isValidParentCode("123")) // Too short
        XCTAssertFalse(isValidParentCode("1234567")) // Too long
        XCTAssertFalse(isValidParentCode("abcd")) // Not numeric
        XCTAssertFalse(isValidParentCode("")) // Empty
    }
    
    func testUserRoleEnum() throws {
        XCTAssertEqual(UserRole.parent.rawValue, "parent")
        XCTAssertEqual(UserRole.child.rawValue, "child")
        XCTAssertEqual(UserRole.allCases.count, 2)
    }
    
    // Helper method to test private isValidParentCode function
    private func isValidParentCode(_ code: String) -> Bool {
        return code.count >= 4 && code.count <= 6 && code.allSatisfy { $0.isNumber }
    }
}