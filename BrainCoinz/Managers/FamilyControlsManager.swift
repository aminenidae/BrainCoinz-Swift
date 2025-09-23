//
//  FamilyControlsManager.swift
//  BrainCoinz
//
//  Manages Family Controls authorization and app selection functionality
//  Handles the interface between the app and Apple's FamilyControls framework
//

import Foundation
import SwiftUI
import FamilyControls
import ManagedSettings
import CoreData

/**
 * Manager responsible for Family Controls integration including:
 * - Authorization flow for parental controls
 * - App selection interface for learning and reward apps
 * - Permission management and status monitoring
 */
class FamilyControlsManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var selectedLearningApps: FamilyActivitySelection = FamilyActivitySelection()
    @Published var selectedRewardApps: FamilyActivitySelection = FamilyActivitySelection()
    @Published var isShowingAppPicker = false
    @Published var currentPickerType: AppPickerType = .learning
    
    // MARK: - Types
    enum AppPickerType {
        case learning
        case reward
    }
    
    // MARK: - Private Properties
    private let authorizationCenter = AuthorizationCenter.shared
    
    // MARK: - Initialization
    init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Public Methods
    
    /**
     * Requests Family Controls authorization from the user
     * This must be called before any other Family Controls functionality
     */
    func requestAuthorization() async {
        do {
            try await authorizationCenter.requestAuthorization(for: .individual)
            await MainActor.run {
                self.checkAuthorizationStatus()
            }
        } catch {
            print("Failed to request Family Controls authorization: \(error)")
            await MainActor.run {
                self.authorizationStatus = .denied
                self.isAuthorized = false
            }
        }
    }
    
    /**
     * Shows the app picker for selecting learning apps
     */
    func selectLearningApps() {
        guard isAuthorized else {
            print("Family Controls not authorized")
            return
        }
        
        currentPickerType = .learning
        isShowingAppPicker = true
    }
    
    /**
     * Shows the app picker for selecting reward apps
     */
    func selectRewardApps() {
        guard isAuthorized else {
            print("Family Controls not authorized")
            return
        }
        
        currentPickerType = .reward
        isShowingAppPicker = true
    }
    
    /**
     * Updates the selected apps based on picker type
     */
    func updateSelectedApps(_ selection: FamilyActivitySelection) {
        switch currentPickerType {
        case .learning:
            selectedLearningApps = selection
            print("Updated learning apps: \(selection.applications.count) apps selected")
        case .reward:
            selectedRewardApps = selection
            print("Updated reward apps: \(selection.applications.count) apps selected")
        }
        
        isShowingAppPicker = false
    }
    
    /**
     * Gets the display names for selected learning apps
     */
    func getLearningAppNames() -> [String] {
        return getAppNames(from: selectedLearningApps)
    }
    
    /**
     * Gets the display names for selected reward apps
     */
    func getRewardAppNames() -> [String] {
        return getAppNames(from: selectedRewardApps)
    }
    
    /**
     * Clears all selected learning apps
     */
    func clearLearningApps() {
        selectedLearningApps = FamilyActivitySelection()
    }
    
    /**
     * Clears all selected reward apps
     */
    func clearRewardApps() {
        selectedRewardApps = FamilyActivitySelection()
    }
    
    /**
     * Checks if any learning apps are selected
     */
    func hasLearningApps() -> Bool {
        return !selectedLearningApps.applications.isEmpty || !selectedLearningApps.categories.isEmpty
    }
    
    /**
     * Checks if any reward apps are selected
     */
    func hasRewardApps() -> Bool {
        return !selectedRewardApps.applications.isEmpty || !selectedRewardApps.categories.isEmpty
    }
    
    /**
     * Gets the bundle identifiers for learning apps
     * Fixed the optional unwrapping issue by filtering out nil values
     */
    func getLearningAppBundleIDs() -> Set<String> {
        return Set(selectedLearningApps.applications.compactMap { $0.bundleIdentifier })
    }
    
    /**
     * Gets the bundle identifiers for reward apps
     * Fixed the optional unwrapping issue by filtering out nil values
     */
    func getRewardAppBundleIDs() -> Set<String> {
        return Set(selectedRewardApps.applications.compactMap { $0.bundleIdentifier })
    }
    
    /**
     * Creates a SelectedApp entity for each learning app
     */
    func createLearningAppEntities(for goal: LearningGoal, context: NSManagedObjectContext) {
        for application in selectedLearningApps.applications {
            let selectedApp = SelectedApp(context: context)
            selectedApp.appBundleID = application.bundleIdentifier ?? ""
            selectedApp.appName = application.localizedDisplayName ?? "Unknown App"
            selectedApp.appType = "learning"
            selectedApp.selectedAt = Date()
            selectedApp.isBlocked = false
            selectedApp.learningGoal = goal
        }
    }
    
    /**
     * Creates a SelectedApp entity for each reward app
     */
    func createRewardAppEntities(for goal: LearningGoal, context: NSManagedObjectContext) {
        for application in selectedRewardApps.applications {
            let selectedApp = SelectedApp(context: context)
            selectedApp.appBundleID = application.bundleIdentifier ?? ""
            selectedApp.appName = application.localizedDisplayName ?? "Unknown App"
            selectedApp.appType = "reward"
            selectedApp.selectedAt = Date()
            selectedApp.isBlocked = true // Reward apps start blocked
            selectedApp.rewardGoal = goal
        }
    }
    
    // MARK: - Private Methods
    
    /**
     * Checks the current authorization status
     */
    private func checkAuthorizationStatus() {
        authorizationStatus = authorizationCenter.authorizationStatus
        isAuthorized = authorizationStatus == .approved
        
        print("Family Controls authorization status: \(authorizationStatus)")
    }
    
    /**
     * Extracts app names from a FamilyActivitySelection
     */
    private func getAppNames(from selection: FamilyActivitySelection) -> [String] {
        return selection.applications.compactMap { application in
            return application.localizedDisplayName
        }
    }
}

/**
 * SwiftUI View for the Family Activity Picker
 */
struct FamilyActivityPickerView: View {
    @Binding var selection: FamilyActivitySelection
    @Binding var isPresented: Bool
    let pickerType: FamilyControlsManager.AppPickerType
    
    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle(pickerType == .learning ? "Select Learning Apps" : "Select Reward Apps")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            isPresented = false
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            isPresented = false
                        }
                        .fontWeight(.semibold)
                    }
                }
        }
    }
}

// MARK: - Extensions

extension AuthorizationStatus {
    var displayName: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .denied:
            return "Denied"
        case .approved:
            return "Approved"
        @unknown default:
            return "Unknown"
        }
    }
    
    var description: String {
        switch self {
        case .notDetermined:
            return "Family Controls authorization has not been requested yet."
        case .denied:
            return "Family Controls authorization has been denied. Please enable it in Settings."
        case .approved:
            return "Family Controls authorization has been granted."
        @unknown default:
            return "Unknown authorization status."
        }
    }
}

extension FamilyActivitySelection {
    /**
     * Returns true if the selection contains any apps or categories
     */
    var isEmpty: Bool {
        return applications.isEmpty && categories.isEmpty
    }
    
    /**
     * Returns the total count of selected items
     */
    var totalCount: Int {
        return applications.count + categories.count
    }
}