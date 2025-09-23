//
//  CoinzManager.swift
//  BrainCoinz
//
//  Core manager for the Coinz reward system
//  Handles earning, spending, and tracking of learning incentives
//

import Foundation
import SwiftUI
import CloudKit
import DeviceActivity
import ManagedSettings
import Combine
import BrainCoinz

/**
 * Core manager for the Coinz reward system that gamifies learning by allowing
 * children to earn virtual coins through educational app usage and spend them
 * to unlock entertainment apps. Integrates with Screen Time APIs for automatic
 * time tracking and app control.
 */
class CoinzManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentWallet: CoinzWallet?
    @Published var appConfigurations: [AppCoinzConfig] = []
    @Published var recentTransactions: [CoinzTransaction] = []
    @Published var activeGoals: [CoinzGoal] = []
    @Published var isEarningActive = false
    @Published var currentEarningApp: AppCoinzConfig?
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    
    // MARK: - Types
    enum SyncStatus {
        case idle
        case syncing
        case success
        case failed(Error)
    }
    
    // MARK: - Private Properties
    private let container = CKContainer.default()
    private let privateDatabase: CKDatabase
    private let sharedDatabase: CKDatabase
    private var familyZone: CKRecordZone?
    private var cancellables = Set<AnyCancellable>()
    private let currentDeviceID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    private let currentUserID = UUID().uuidString // In real app, use consistent user ID
    
    // Device Activity monitoring
    private var deviceActivityManager: DeviceActivityManager?
    private var managedSettingsManager: ManagedSettingsManager?
    
    // Timer for tracking learning sessions
    private var learningTimer: Timer?
    private var currentLearningStartTime: Date?
    private var accumulatedLearningMinutes = 0
    
    // MARK: - Initialization
    init() {
        self.privateDatabase = container.privateCloudDatabase
        self.sharedDatabase = container.sharedCloudDatabase
        setupDefaultConfigurations()
        loadUserWallet()
        startDeviceActivityMonitoring()
    }
    
    // MARK: - Public Methods
    
    /**
     * Starts earning session for a learning app
     * @param appConfig: Configuration for the learning app
     */
    func startEarningSession(for appConfig: AppCoinzConfig) {
        guard appConfig.category == .learning && appConfig.isEnabled else { return }
        
        currentEarningApp = appConfig
        currentLearningStartTime = Date()
        isEarningActive = true
        accumulatedLearningMinutes = 0
        
        // Start timer to track learning time and award Coinz
        startLearningTimer()
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: .coinzEarningStarted, object: appConfig)
    }
    
    /**
     * Ends current earning session and awards Coinz
     */
    func endEarningSession() {
        guard let appConfig = currentEarningApp,
              let startTime = currentLearningStartTime else { return }
        
        let totalMinutes = accumulatedLearningMinutes + Int(Date().timeIntervalSince(startTime) / 60)
        let coinzEarned = totalMinutes * appConfig.coinzRate
        
        if coinzEarned > 0 {
            awardCoinz(coinzEarned, for: appConfig, timeSpent: totalMinutes)
        }
        
        // Reset earning state
        isEarningActive = false
        currentEarningApp = nil
        currentLearningStartTime = nil
        accumulatedLearningMinutes = 0
        learningTimer?.invalidate()
        learningTimer = nil
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: .coinzEarningEnded, object: coinzEarned)
    }
    
    /**
     * Attempts to spend Coinz to unlock a reward app with daily time limit validation
     * @param appConfig: Configuration for the reward app
     * @param minutes: Number of minutes to unlock
     * @returns: Success status
     */
    func spendCoinzForRewardApp(_ appConfig: AppCoinzConfig, minutes: Int) -> Bool {
        guard appConfig.category == .reward,
              appConfig.isEnabled,
              var wallet = currentWallet else {
            return false
        }
        
        // Use the new economy system validation
        let purchaseValidation = wallet.canPurchaseTime(for: appConfig, minutes: minutes)
        guard purchaseValidation.canPurchase else {
            // Show specific error message based on validation failure
            if let reason = purchaseValidation.reason {
                showPurchaseFailedAlert(reason: reason)
            }
            return false
        }
        
        let totalCost = abs(appConfig.coinzRate) * minutes
        
        // Spend Coinz from wallet
        guard wallet.spendCoinz(totalCost, for: appConfig) else {
            showInsufficientBalanceAlert(needed: totalCost, available: wallet.currentBalance)
            return false
        }
        
        // Track daily reward app usage
        wallet.addRewardUsage(for: appConfig.bundleID, minutes: minutes)
        
        // Update wallet
        currentWallet = wallet
        saveWallet()
        
        // Create transaction record
        let transaction = CoinzTransaction(
            walletID: wallet.id,
            appBundleID: appConfig.bundleID,
            appDisplayName: appConfig.displayName,
            transactionType: .spent,
            coinzAmount: -totalCost,
            timeSpentMinutes: minutes
        )
        
        addTransaction(transaction)
        
        // Unlock the reward app for specified duration
        unlockRewardApp(appConfig, for: minutes)
        
        // Post notification
        NotificationCenter.default.post(name: .coinzSpent, object: [
            "appConfig": appConfig,
            "amount": totalCost,
            "minutes": minutes
        ])
        
        return true
    }
    
    /**
     * Checks affordability using the economy system (considers learning requirement, Coinz balance, and daily time limits)
     * @param appConfig: Configuration for the reward app
     * @returns: Tuple of (canAfford, affordableMinutes, learningRequirementMet, remainingDailyTime)
     */
    func checkAffordability(for appConfig: AppCoinzConfig) -> (canAfford: Bool, minutes: Int, learningRequirementMet: Bool, remainingDailyTime: Int) {
        guard let wallet = currentWallet else { return (false, 0, false, 0) }
        
        let affordableMinutes = wallet.affordableMinutes(for: appConfig)
        let hasMetLearningRequirement = wallet.hasMetDailyLearningRequirement
        let remainingDailyTime = wallet.getRemainingDailyTime(for: appConfig)
        
        return (affordableMinutes > 0 && hasMetLearningRequirement, affordableMinutes, hasMetLearningRequirement, remainingDailyTime)
    }
    
    /**
     * Awards bonus Coinz (parent-initiated)
     * @param amount: Amount of Coinz to award
     * @param reason: Reason for the bonus
     */
    func awardBonusCoinz(_ amount: Int, reason: String) {
        guard var wallet = currentWallet else { return }
        
        wallet.earnCoinz(amount, from: AppCoinzConfig(bundleID: "bonus", displayName: "Bonus", category: .learning))
        currentWallet = wallet
        saveWallet()
        
        // Create bonus transaction
        let transaction = CoinzTransaction(
            walletID: wallet.id,
            appBundleID: "bonus",
            appDisplayName: reason,
            transactionType: .bonus,
            coinzAmount: amount,
            timeSpentMinutes: 0
        )
        
        addTransaction(transaction)
        
        // Show celebration notification
        showBonusReceivedNotification(amount: amount, reason: reason)
    }
    
    /**
     * Applies penalty (parent-initiated)
     * @param amount: Amount of Coinz to deduct
     * @param reason: Reason for the penalty
     */
    func applyPenalty(_ amount: Int, reason: String) {
        guard var wallet = currentWallet else { return }
        
        // Deduct from balance (can go negative)
        wallet.currentBalance -= amount
        wallet.lastModified = Date()
        currentWallet = wallet
        saveWallet()
        
        // Create penalty transaction
        let transaction = CoinzTransaction(
            walletID: wallet.id,
            appBundleID: "penalty",
            appDisplayName: reason,
            transactionType: .penalty,
            coinzAmount: -amount,
            timeSpentMinutes: 0
        )
        
        addTransaction(transaction)
    }
    
    /**
     * Gets app configuration by bundle ID
     */
    func getAppConfig(for bundleID: String) -> AppCoinzConfig? {
        return appConfigurations.first { $0.bundleID == bundleID }
    }
    
    /**
     * Updates app configuration (parent only)
     */
    func updateAppConfig(_ config: AppCoinzConfig) {
        if let index = appConfigurations.firstIndex(where: { $0.id == config.id }) {
            appConfigurations[index] = config
            saveAppConfigurations()
        }
    }
    
    /**
     * Adds new app configuration
     */
    func addAppConfig(_ config: AppCoinzConfig) {
        appConfigurations.append(config)
        saveAppConfigurations()
    }
    
    /**
     * Gets learning apps (earning Coinz)
     */
    func getLearningApps() -> [AppCoinzConfig] {
        return appConfigurations.filter { $0.category == .learning && $0.isEnabled }
    }
    
    /**
     * Gets reward apps (spending Coinz)
     */
    func getRewardApps() -> [AppCoinzConfig] {
        return appConfigurations.filter { $0.category == .reward && $0.isEnabled }
    }
    
    /**
     * Creates a new learning goal
     */
    func createGoal(_ goal: CoinzGoal) {
        activeGoals.append(goal)
        saveGoals()
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: .coinzGoalCreated, object: goal)
    }
    
    /**
     * Updates progress on active goals
     */
    func updateGoalProgress(for appBundleID: String, earnedCoinz: Int) {
        var completedGoals: [CoinzGoal] = []
        
        for i in 0..<activeGoals.count {
            if activeGoals[i].appBundleIDs.contains(appBundleID) && 
               activeGoals[i].isActive && !activeGoals[i].isExpired {
                
                if activeGoals[i].updateProgress(earnedCoinz) {
                    // Goal completed - award bonus
                    let goal = activeGoals[i]
                    awardBonusCoinz(goal.bonusCoinz, reason: "Goal Completed: \(goal.title)")
                    completedGoals.append(goal)
                }
            }
        }
        
        // Notify about completed goals
        for goal in completedGoals {
            NotificationCenter.default.post(name: .coinzGoalCompleted, object: goal)
        }
        
        if !completedGoals.isEmpty {
            saveGoals()
        }
    }
    
    /**
     * Gets wallet statistics including learning progress and carryover balance
     */
    func getWalletStats() -> (balance: Int, dailyEarned: Int, dailySpent: Int, totalEarned: Int, totalSpent: Int, 
                             dailyLearningMinutes: Int, minimumLearningMinutes: Int, learningProgressPercentage: Double,
                             carryoverBalance: Int, hasCarryover: Bool) {
        guard let wallet = currentWallet else { 
            return (0, 0, 0, 0, 0, 0, 15, 0.0, 0, false) 
        }
        
        return (
            balance: wallet.currentBalance,
            dailyEarned: wallet.dailyEarned,
            dailySpent: wallet.dailySpent,
            totalEarned: wallet.totalEarned,
            totalSpent: wallet.totalSpent,
            dailyLearningMinutes: wallet.dailyLearningMinutes,
            minimumLearningMinutes: wallet.minimumDailyLearningMinutes,
            learningProgressPercentage: wallet.learningProgressPercentage,
            carryoverBalance: wallet.carryoverBalance,
            hasCarryover: wallet.hasCarryoverBalance
        )
    }
    
    /**
     * Updates minimum daily learning time requirement (parent only)
     */
    func updateMinimumLearningTime(_ minutes: Int) {
        guard var wallet = currentWallet else { return }
        
        wallet.minimumDailyLearningMinutes = max(0, minutes)
        wallet.lastModified = Date()
        currentWallet = wallet
        saveWallet()
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: .minimumLearningTimeUpdated, object: minutes)
    }
    
    // MARK: - Parent Oversight Methods
    
    /**
     * Reset child's Coinz balance (parent-initiated)
     * @param newBalance: New balance to set (default: 0)
     */
    func resetCoinzBalance(to newBalance: Int = 0) {
        guard var wallet = currentWallet else { return }
        
        let oldBalance = wallet.currentBalance
        wallet.currentBalance = max(0, newBalance)  // Prevent negative balances from reset
        wallet.lastModified = Date()
        currentWallet = wallet
        saveWallet()
        
        // Create adjustment transaction
        let transaction = CoinzTransaction(
            walletID: wallet.id,
            appBundleID: "parent_reset",
            appDisplayName: "Balance Reset by Parent",
            transactionType: .adjustment,
            coinzAmount: newBalance - oldBalance,
            timeSpentMinutes: 0
        )
        
        addTransaction(transaction)
        
        // Show notification
        showBalanceAdjustmentNotification(oldBalance: oldBalance, newBalance: newBalance, reason: "Reset by Parent")
    }
    
    /**
     * Increase child's Coinz balance (parent-initiated)
     * @param amount: Amount to add
     * @param reason: Reason for the increase
     */
    func increaseCoinzBalance(_ amount: Int, reason: String = "Parent Bonus") {
        guard var wallet = currentWallet, amount > 0 else { return }
        
        wallet.currentBalance += amount
        wallet.lastModified = Date()
        currentWallet = wallet
        saveWallet()
        
        // Create bonus transaction
        let transaction = CoinzTransaction(
            walletID: wallet.id,
            appBundleID: "parent_bonus",
            appDisplayName: reason,
            transactionType: .bonus,
            coinzAmount: amount,
            timeSpentMinutes: 0
        )
        
        addTransaction(transaction)
        
        // Show celebration notification
        showBonusReceivedNotification(amount: amount, reason: reason)
    }
    
    /**
     * Decrease child's Coinz balance (parent-initiated)
     * @param amount: Amount to deduct
     * @param reason: Reason for the decrease
     */
    func decreaseCoinzBalance(_ amount: Int, reason: String = "Parent Penalty") {
        guard var wallet = currentWallet, amount > 0 else { return }
        
        wallet.currentBalance -= amount  // Allow negative balances for penalties
        wallet.lastModified = Date()
        currentWallet = wallet
        saveWallet()
        
        // Create penalty transaction
        let transaction = CoinzTransaction(
            walletID: wallet.id,
            appBundleID: "parent_penalty",
            appDisplayName: reason,
            transactionType: .penalty,
            coinzAmount: -amount,
            timeSpentMinutes: 0
        )
        
        addTransaction(transaction)
        
        // Show penalty notification
        showPenaltyAppliedNotification(amount: amount, reason: reason)
    }
    
    /**
     * Get daily time limit usage statistics for parent oversight
     */
    func getDailyTimeUsageStats() -> [(appName: String, bundleID: String, usedMinutes: Int, limitMinutes: Int, remainingMinutes: Int)] {
        guard let wallet = currentWallet else { return [] }
        
        return getRewardApps().map { appConfig in
            let usedMinutes = wallet.dailyRewardUsage[appConfig.bundleID] ?? 0
            let limitMinutes = appConfig.dailyTimeLimit
            let remainingMinutes = limitMinutes > 0 ? max(0, limitMinutes - usedMinutes) : Int.max
            
            return (
                appName: appConfig.displayName,
                bundleID: appConfig.bundleID,
                usedMinutes: usedMinutes,
                limitMinutes: limitMinutes,
                remainingMinutes: remainingMinutes == Int.max ? -1 : remainingMinutes  // -1 means unlimited
            )
        }
    }
    
    // MARK: - Private Methods
    
    /**
     * Sets up default app configurations
     */
    private func setupDefaultConfigurations() {
        // Load predefined apps with custom rates
        var configs = PredefinedApps.learningApps + PredefinedApps.rewardApps
        
        // Apply custom rates
        let customLearningRates = PredefinedApps.createCustomLearningRates()
        let customRewardRates = PredefinedApps.createCustomRewardRates()
        
        for i in 0..<configs.count {
            if let customRate = customLearningRates[configs[i].bundleID] {
                configs[i].coinzRate = customRate
            } else if let customRate = customRewardRates[configs[i].bundleID] {
                configs[i].coinzRate = customRate
            }
        }
        
        appConfigurations = configs
    }
    
    /**
     * Loads or creates user wallet
     */
    private func loadUserWallet() {
        // Try to load existing wallet from CloudKit or local storage
        // For now, create a new wallet
        if currentWallet == nil {
            currentWallet = CoinzWallet(userID: currentUserID, deviceID: currentDeviceID)
            saveWallet()
        }
        
        // Reset daily counters if needed
        currentWallet?.resetDailyCountersIfNeeded()
    }
    
    /**
     * Starts device activity monitoring for automatic earning
     */
    private func startDeviceActivityMonitoring() {
        // This would integrate with DeviceActivity framework
        // to automatically detect app usage and start/stop earning sessions
    }
    
    /**
     * Starts learning timer for active earning
     */
    private func startLearningTimer() {
        learningTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.processLearningMinute()
        }
    }
    
    /**
     * Processes one minute of learning time
     */
    private func processLearningMinute() {
        guard let appConfig = currentEarningApp else { return }
        
        accumulatedLearningMinutes += 1
        let coinzEarned = appConfig.coinzRate
        
        // Award Coinz for this minute and track learning time
        if coinzEarned > 0 {
            awardCoinz(coinzEarned, for: appConfig, timeSpent: 1, learningMinutes: 1)
        }
        
        // Update goal progress
        updateGoalProgress(for: appConfig.bundleID, earnedCoinz: coinzEarned)
        
        // Check if minimum learning requirement has just been met
        if let wallet = currentWallet, 
           wallet.dailyLearningMinutes == wallet.minimumDailyLearningMinutes {
            showLearningRequirementMetNotification()
        }
    }
    
    /**
     * Awards Coinz to the user's wallet
     */
    private func awardCoinz(_ amount: Int, for appConfig: AppCoinzConfig, timeSpent: Int, learningMinutes: Int = 0) {
        guard var wallet = currentWallet else { return }
        
        wallet.earnCoinz(amount, from: appConfig, learningMinutes: learningMinutes)
        currentWallet = wallet
        saveWallet()
        
        // Create transaction record
        let transaction = CoinzTransaction(
            walletID: wallet.id,
            appBundleID: appConfig.bundleID,
            appDisplayName: appConfig.displayName,
            transactionType: .earned,
            coinzAmount: amount,
            timeSpentMinutes: timeSpent
        )
        
        addTransaction(transaction)
        
        // Show earning notification
        if amount > 0 {
            showCoinzEarnedNotification(amount: amount, appName: appConfig.displayName)
        }
    }
    
    /**
     * Unlocks reward app for specified duration
     */
    private func unlockRewardApp(_ appConfig: AppCoinzConfig, for minutes: Int) {
        // This would integrate with ManagedSettings to temporarily unblock the app
        // For now, just show a notification
        showRewardAppUnlockedNotification(appName: appConfig.displayName, minutes: minutes)
        
        // Schedule re-blocking after the specified time
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(minutes * 60)) {
            self.blockRewardApp(appConfig)
        }
    }
    
    /**
     * Blocks reward app after time expires
     */
    private func blockRewardApp(_ appConfig: AppCoinzConfig) {
        // This would use ManagedSettings to block the app
        showRewardAppBlockedNotification(appName: appConfig.displayName)
    }
    
    /**
     * Adds transaction to history
     */
    private func addTransaction(_ transaction: CoinzTransaction) {
        recentTransactions.insert(transaction, at: 0)
        
        // Keep only last 100 transactions
        if recentTransactions.count > 100 {
            recentTransactions.removeLast()
        }
        
        saveTransactions()
    }
    
    /**
     * Saves wallet to CloudKit
     */
    private func saveWallet() {
        guard let wallet = currentWallet,
              let familyZone = familyZone else { return }
        
        let record = wallet.toCloudKitRecord(in: familyZone.zoneID)
        privateDatabase.save(record) { _, error in
            if let error = error {
                print("Failed to save wallet: \(error)")
            }
        }
    }
    
    /**
     * Saves app configurations to CloudKit
     */
    private func saveAppConfigurations() {
        guard let familyZone = familyZone else { return }
        
        let records = appConfigurations.map { $0.toCloudKitRecord(in: familyZone.zoneID) }
        
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        operation.savePolicy = .allKeys
        operation.modifyRecordsCompletionBlock = { _, _, error in
            if let error = error {
                print("Failed to save app configurations: \(error)")
            }
        }
        
        privateDatabase.add(operation)
    }
    
    /**
     * Saves transactions to CloudKit
     */
    private func saveTransactions() {
        // Implementation for saving transactions to CloudKit
    }
    
    /**
     * Saves goals to CloudKit
     */
    private func saveGoals() {
        // Implementation for saving goals to CloudKit
    }
    
    // MARK: - Notification Methods
    
    private func showCoinzEarnedNotification(amount: Int, appName: String) {
        let notification = UNMutableNotificationContent()
        notification.title = "💰 Coinz Earned!"
        notification.body = "You earned \(amount) Coinz from \(appName)!"
        notification.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notification, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func showBonusReceivedNotification(amount: Int, reason: String) {
        let notification = UNMutableNotificationContent()
        notification.title = "🎉 Bonus Coinz!"
        notification.body = "You received \(amount) bonus Coinz for: \(reason)"
        notification.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notification, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func showRewardAppUnlockedNotification(appName: String, minutes: Int) {
        let notification = UNMutableNotificationContent()
        notification.title = "🎮 App Unlocked!"
        notification.body = "\(appName) is now unlocked for \(minutes) minutes. Enjoy!"
        notification.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notification, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func showRewardAppBlockedNotification(appName: String) {
        let notification = UNMutableNotificationContent()
        notification.title = "⏰ Time's Up!"
        notification.body = "\(appName) is now blocked. Earn more Coinz to play again!"
        notification.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notification, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func showPurchaseFailedAlert(reason: String) {
        let notification = UNMutableNotificationContent()
        notification.title = "❌ Cannot Purchase"
        notification.body = reason
        notification.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notification, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func showInsufficientBalanceAlert(needed: Int, available: Int) {
        let notification = UNMutableNotificationContent()
        notification.title = "💰 Not Enough Coinz!"
        notification.body = "You need \(needed) Coinz but only have \(available). Use learning apps to earn more!"
        notification.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notification, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func showMinimumLearningTimeAlert(required: Int, current: Int) {
        let remaining = required - current
        let notification = UNMutableNotificationContent()
        notification.title = "📚 Learning Time Required!"
        notification.body = "Complete \(remaining) more minutes of learning to unlock reward apps. You've done \(current)/\(required) minutes today."
        notification.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notification, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func showLearningRequirementMetNotification() {
        let notification = UNMutableNotificationContent()
        notification.title = "🎉 Learning Goal Complete!"
        notification.body = "Great job! You've completed your daily learning time. Reward apps are now unlocked!"
        notification.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notification, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func showBalanceAdjustmentNotification(oldBalance: Int, newBalance: Int, reason: String) {
        let notification = UNMutableNotificationContent()
        notification.title = "💰 Balance Updated"
        
        if newBalance > oldBalance {
            notification.body = "Your balance increased from \(oldBalance) to \(newBalance) Coinz. Reason: \(reason)"
        } else if newBalance < oldBalance {
            notification.body = "Your balance changed from \(oldBalance) to \(newBalance) Coinz. Reason: \(reason)"
        } else {
            notification.body = "Your balance was reset to \(newBalance) Coinz. Reason: \(reason)"
        }
        
        notification.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notification, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func showPenaltyAppliedNotification(amount: Int, reason: String) {
        let notification = UNMutableNotificationContent()
        notification.title = "⚠️ Coinz Penalty"
        notification.body = "\(amount) Coinz were deducted. Reason: \(reason)"
        notification.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notification, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let coinzEarningStarted = Notification.Name("coinzEarningStarted")
    static let coinzEarningEnded = Notification.Name("coinzEarningEnded")
    static let coinzEarned = Notification.Name("coinzEarned")
    static let coinzSpent = Notification.Name("coinzSpent")
    static let coinzGoalCreated = Notification.Name("coinzGoalCreated")
    static let coinzGoalCompleted = Notification.Name("coinzGoalCompleted")
    static let coinzBalanceUpdated = Notification.Name("coinzBalanceUpdated")
    static let rewardAppUnlocked = Notification.Name("rewardAppUnlocked")
    static let rewardAppBlocked = Notification.Name("rewardAppBlocked")
    static let minimumLearningTimeUpdated = Notification.Name("minimumLearningTimeUpdated")
    static let learningRequirementMet = Notification.Name("learningRequirementMet")
}