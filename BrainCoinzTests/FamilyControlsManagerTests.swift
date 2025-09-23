//
//  FamilyControlsManagerTests.swift
//  BrainCoinzTests
//
//  Created on 2025-01-14.
//

import XCTest
@testable import BrainCoinz
import FamilyControls

final class FamilyControlsManagerTests: XCTestCase {
    
    var familyControlsManager: FamilyControlsManager!
    
    override func setUpWithError() throws {
        familyControlsManager = FamilyControlsManager()
    }
    
    override func tearDownWithError() throws {
        familyControlsManager = nil
    }
    
    func testInitialState() throws {
        XCTAssertFalse(familyControlsManager.isAuthorized)
        XCTAssertEqual(familyControlsManager.authorizationStatus, .notDetermined)
        XCTAssertFalse(familyControlsManager.isShowingAppPicker)
        XCTAssertEqual(familyControlsManager.currentPickerType, .learning)
    }
    
    func testAppPickerTypeEnum() throws {
        XCTAssertEqual(FamilyControlsManager.AppPickerType.learning, .learning)
        XCTAssertEqual(FamilyControlsManager.AppPickerType.reward, .reward)
    }
    
    func testFamilyActivitySelectionExtensions() throws {
        let emptySelection = FamilyActivitySelection()
        XCTAssertTrue(emptySelection.isEmpty)
        XCTAssertEqual(emptySelection.totalCount, 0)
    }
    
    func testAuthorizationStatusExtensions() throws {
        XCTAssertEqual(AuthorizationStatus.notDetermined.displayName, "Not Determined")
        XCTAssertEqual(AuthorizationStatus.denied.displayName, "Denied")
        XCTAssertEqual(AuthorizationStatus.approved.displayName, "Approved")
        
        XCTAssertFalse(AuthorizationStatus.notDetermined.displayName.isEmpty)
        XCTAssertFalse(AuthorizationStatus.denied.displayName.isEmpty)
        XCTAssertFalse(AuthorizationStatus.approved.displayName.isEmpty)
    }
}