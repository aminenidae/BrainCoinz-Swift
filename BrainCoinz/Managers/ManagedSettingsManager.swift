//
//  ManagedSettingsManager.swift
//  BrainCoinz
//
//  Manages app blocking and unblocking through Apple's ManagedSettings framework
//  Controls access to reward apps based on learning goal completion
//

import Foundation
import SwiftUI
import ManagedSettings
import FamilyControls

/**
 * Manager responsible for controlling app access through ManagedSettings.
 * This class handles blocking reward apps initially and unblocking them
 * when learning goals are completed.
 */
class ManagedSettingsManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isRewardAppsBlocked = false
    @Published var blockedAppsCount = 0
    @Published var lastBlockingUpdate = Date()
    
    // MARK: - Private Properties
    private let managedSettingsStore = ManagedSettingsStore()
    private var currentRewardApps: Set<ApplicationToken> = []
    private var currentLearningApps: Set<ApplicationToken> = []
    
    // MARK: - Initialization
    init() {
        setupNotificationObservers()
    }
    
    // MARK: - Public Methods
    
    /**
     * Initializes the ManagedSettings manager
     */
    func initialize() {
        print("ManagedSettingsManager initialized")
    }
    
    /**
     * Blocks reward apps until learning goal is completed
     * @param rewardApps: Set of ApplicationTokens for reward apps to block
     * @param learningApps: Set of ApplicationTokens for learning apps (allowed)
     */
    func blockRewardApps(_ rewardApps: Set<ApplicationToken>, allowLearningApps learningApps: Set<ApplicationToken>) {
        currentRewardApps = rewardApps
        currentLearningApps = learningApps
        
        guard !rewardApps.isEmpty else {
            print("No reward apps to block")
            return
        }
        
        // Apply application restrictions to block reward apps
        managedSettingsStore.application.blockedApplications = rewardApps
        
        // Optionally, we could set up shields for blocked apps
        configureShieldSettings()
        
        DispatchQueue.main.async {
            self.isRewardAppsBlocked = true
            self.blockedAppsCount = rewardApps.count
            self.lastBlockingUpdate = Date()
        }
        
        print("Blocked \(rewardApps.count) reward apps")
    }
    
    /**
     * Unblocks reward apps when learning goal is completed
     */
    func unblockRewardApps() {
        // Clear all application restrictions
        managedSettingsStore.application.blockedApplications = Set<ApplicationToken>()
        
        // Clear shield restrictions
        managedSettingsStore.shield.applications = Set<ApplicationToken>()
        managedSettingsStore.shield.applicationCategories = Set<ActivityCategoryToken>()
        
        DispatchQueue.main.async {
            self.isRewardAppsBlocked = false
            self.blockedAppsCount = 0
            self.lastBlockingUpdate = Date()
        }
        
        print("Unblocked all reward apps - goal completed!")
    }
    
    /**
     * Applies temporary blocking (for testing or manual control)
     * @param apps: Apps to temporarily block
     * @param duration: Duration in minutes to block
     */
    func temporaryBlock(_ apps: Set<ApplicationToken>, for duration: TimeInterval) {
        blockRewardApps(apps, allowLearningApps: currentLearningApps)
        
        // Schedule automatic unblocking
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.unblockRewardApps()
        }
        
        print("Temporarily blocked \(apps.count) apps for \(duration/60) minutes")
    }
    
    /**
     * Sets up a daily schedule for automatic blocking/unblocking
     * @param blockStartTime: Time to start blocking (e.g., school hours)
     * @param blockEndTime: Time to end blocking
     */
    func setupDailySchedule(blockStart: DateComponents, blockEnd: DateComponents) {
        // This would require DeviceActivity integration for time-based restrictions
        let schedule = DeviceActivitySchedule(
            intervalStart: blockStart,
            intervalEnd: blockEnd,
            repeats: true
        )
        
        print("Daily schedule configured: \(blockStart) to \(blockEnd)")
    }
    
    /**
     * Gets the current blocking status
     */
    func getBlockingStatus() -> BlockingStatus {
        return BlockingStatus(
            isBlocked: isRewardAppsBlocked,
            blockedAppsCount: blockedAppsCount,
            lastUpdate: lastBlockingUpdate,
            rewardApps: Array(currentRewardApps),
            learningApps: Array(currentLearningApps)
        )
    }
    
    /**
     * Clears all managed settings (for reset or logout)
     */
    func clearAllSettings() {
        managedSettingsStore.application.blockedApplications = Set<ApplicationToken>()
        managedSettingsStore.shield.applications = Set<ApplicationToken>()
        managedSettingsStore.shield.applicationCategories = Set<ActivityCategoryToken>()
        
        DispatchQueue.main.async {
            self.isRewardAppsBlocked = false
            self.blockedAppsCount = 0
            self.lastBlockingUpdate = Date()
        }
        
        currentRewardApps.removeAll()
        currentLearningApps.removeAll()
        
        print("Cleared all managed settings")
    }
    
    /**
     * Sets up parental override for emergency access
     * @param completion: Callback when override is granted or denied
     */
    func requestParentalOverride(completion: @escaping (Bool) -> Void) {
        // This would integrate with AuthenticationManager for parent verification
        NotificationCenter.default.post(
            name: .parentalOverrideRequested,
            object: nil,
            userInfo: ["completion": completion]
        )
    }
    
    // MARK: - Private Methods
    
    /**
     * Configures shield settings for blocked apps
     */
    private func configureShieldSettings() {
        // Set up custom shield for blocked reward apps
        managedSettingsStore.shield.applications = currentRewardApps
        
        // Could add custom shield restrictions here
        // For example, requiring parent authentication to access blocked apps
    }
    
    /**
     * Sets up notification observers for goal completion
     */
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGoalCompleted),
            name: .goalCompleted,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDailyReset),
            name: .dailyReset,
            object: nil
        )
    }
    
    /**
     * Handles goal completion notification
     */
    @objc private func handleGoalCompleted(_ notification: Notification) {
        guard let goal = notification.object as? LearningGoal else { return }
        
        print("Received goal completion notification for user: \(goal.user?.name ?? "Unknown")")
        unblockRewardApps()
        
        // Send notification to child about unlocked apps
        NotificationCenter.default.post(
            name: .rewardAppsUnlocked,
            object: goal
        )
    }
    
    /**
     * Handles daily reset (midnight) to re-block reward apps
     */
    @objc private func handleDailyReset(_ notification: Notification) {
        if !currentRewardApps.isEmpty {
            blockRewardApps(currentRewardApps, allowLearningApps: currentLearningApps)
            print("Daily reset: Reward apps blocked again")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Supporting Types

/**
 * Represents the current blocking status
 */
struct BlockingStatus {
    let isBlocked: Bool
    let blockedAppsCount: Int
    let lastUpdate: Date
    let rewardApps: [ApplicationToken]
    let learningApps: [ApplicationToken]
    
    var blockedAppNames: [String] {
        return rewardApps.compactMap { token in
            // In a real implementation, you'd need to resolve token to app name
            return "Reward App" // Placeholder
        }
    }
}

/**
 * Configuration for app blocking policies
 */
struct BlockingPolicy {
    let allowLearningApps: Bool
    let blockSocialMedia: Bool
    let blockGames: Bool
    let allowEducationalGames: Bool
    let emergencyBypass: Bool
    
    static let `default` = BlockingPolicy(
        allowLearningApps: true,
        blockSocialMedia: true,
        blockGames: true,
        allowEducationalGames: true,
        emergencyBypass: true
    )
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let rewardAppsUnlocked = Notification.Name("rewardAppsUnlocked")
    static let parentalOverrideRequested = Notification.Name("parentalOverrideRequested")
    static let dailyReset = Notification.Name("dailyReset")
}

// MARK: - Error Types

enum ManagedSettingsError: Error, LocalizedError {
    case unauthorized
    case invalidApplicationTokens
    case blockingFailed
    case unblockingFailed
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Not authorized to manage settings"
        case .invalidApplicationTokens:
            return "Invalid application tokens provided"
        case .blockingFailed:
            return "Failed to block applications"
        case .unblockingFailed:
            return "Failed to unblock applications"
        }
    }
}

// MARK: - Extensions

extension ManagedSettingsManager {
    
    /**
     * Applies a preset blocking configuration
     */
    func applyBlockingPolicy(_ policy: BlockingPolicy, rewardApps: Set<ApplicationToken>, learningApps: Set<ApplicationToken>) {
        if policy.allowLearningApps {
            // Allow learning apps through whitelist
            managedSettingsStore.application.blockedApplications = rewardApps
        } else {
            // Block everything except system apps
            managedSettingsStore.application.blockedApplications = rewardApps.union(learningApps)
        }
        
        configureShieldSettings()
        
        print("Applied blocking policy: \(policy)")
    }
    
    /**
     * Gets usage data for blocked apps (when available)
     */
    func getBlockedAppAttempts() -> [String: Int] {
        // This would require DeviceActivity integration to track blocked app launch attempts
        // Placeholder implementation
        return [:]
    }
}