//
//  CoinzModels.swift
//  BrainCoinz
//
//  Core data models for the Coinz reward system
//  Implements point-based learning incentives and screen time costs
//

import Foundation
import CloudKit

// MARK: - Core Coinz Models

/**
 * App category for earning and spending Coinz
 */
enum AppCategory: String, CaseIterable {
    case learning = "learning"       // Apps that earn Coinz
    case reward = "reward"          // Apps that cost Coinz
    case neutral = "neutral"        // Apps that don't affect Coinz
    
    var displayName: String {
        switch self {
        case .learning:
            return "Learning Apps"
        case .reward:
            return "Reward Apps"
        case .neutral:
            return "Neutral Apps"
        }
    }
    
    var iconName: String {
        switch self {
        case .learning:
            return "book.fill"
        case .reward:
            return "gamecontroller.fill"
        case .neutral:
            return "app.fill"
        }
    }
    
    var color: String {
        switch self {
        case .learning:
            return "green"
        case .reward:
            return "orange"
        case .neutral:
            return "gray"
        }
    }
}

/**
 * App configuration with earning/spending rates and time limits
 */
struct AppCoinzConfig: Identifiable, Codable {
    let id: UUID
    let bundleID: String
    let displayName: String
    let category: AppCategory
    var coinzRate: Int                  // Coinz per minute (positive for earning, negative for spending)
    var dailyTimeLimit: Int            // Daily time limit in minutes for reward apps (0 = unlimited)
    var isEnabled: Bool
    var customIcon: String?
    let createdAt: Date
    var lastModified: Date
    
    // Default rates based on category
    static let defaultLearningRate = 1  // 1 Coinz per minute
    static let defaultRewardRate = -5   // -5 Coinz per minute (costs 5 Coinz)
    
    init(bundleID: String, displayName: String, category: AppCategory) {
        self.id = UUID()
        self.bundleID = bundleID
        self.displayName = displayName
        self.category = category
        self.coinzRate = category == .learning ? Self.defaultLearningRate : 
                        category == .reward ? Self.defaultRewardRate : 0
        self.dailyTimeLimit = category == .reward ? 30 : 0  // Default 30 min for reward apps
        self.isEnabled = true
        self.createdAt = Date()
        self.lastModified = Date()
    }
    
    /**
     * Create from CloudKit record
     */
    init(from record: CKRecord) throws {
        guard let bundleID = record["bundleID"] as? String,
              let displayName = record["displayName"] as? String,
              let categoryString = record["category"] as? String,
              let category = AppCategory(rawValue: categoryString),
              let coinzRate = record["coinzRate"] as? Int,
              let isEnabled = record["isEnabled"] as? Bool,
              let createdAt = record["createdAt"] as? Date,
              let lastModified = record["lastModified"] as? Date else {
            throw CoinzError.invalidRecord
        }
        
        self.id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        self.bundleID = bundleID
        self.displayName = displayName
        self.category = category
        self.coinzRate = coinzRate
        self.dailyTimeLimit = record["dailyTimeLimit"] as? Int ?? (category == .reward ? 30 : 0)
        self.isEnabled = isEnabled
        self.customIcon = record["customIcon"] as? String
        self.createdAt = createdAt
        self.lastModified = lastModified
    }
    
    /**
     * Convert to CloudKit record
     */
    func toCloudKitRecord(in zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: "AppCoinzConfig", recordID: recordID)
        
        record["bundleID"] = bundleID
        record["displayName"] = displayName
        record["category"] = category.rawValue
        record["coinzRate"] = coinzRate
        record["dailyTimeLimit"] = dailyTimeLimit
        record["isEnabled"] = isEnabled
        record["customIcon"] = customIcon
        record["createdAt"] = createdAt
        record["lastModified"] = Date() // Update on save
        
        return record
    }
}

/**
 * Coinz wallet for tracking balance and transactions
 */
struct CoinzWallet: Identifiable, Codable {
    let id: UUID
    let userID: String
    let deviceID: String
    var currentBalance: Int
    var totalEarned: Int
    var totalSpent: Int
    var dailyEarned: Int
    var dailySpent: Int
    var dailyLearningMinutes: Int      // Daily learning time accumulated
    var totalLearningMinutes: Int      // Total learning time ever
    var dailyRewardUsage: [String: Int] = [:]  // Bundle ID -> minutes used today
    var minimumDailyLearningMinutes: Int = 15  // Parent-configurable minimum (default 15 min)
    var lastResetDate: Date             // For daily tracking reset
    let createdAt: Date
    var lastModified: Date
    
    init(userID: String, deviceID: String) {
        self.id = UUID()
        self.userID = userID
        self.deviceID = deviceID
        self.currentBalance = 0
        self.totalEarned = 0
        self.totalSpent = 0
        self.dailyEarned = 0
        self.dailySpent = 0
        self.dailyLearningMinutes = 0
        self.totalLearningMinutes = 0
        self.dailyRewardUsage = [:]
        self.minimumDailyLearningMinutes = 15  // Default 15 minutes
        self.lastResetDate = Date()
        self.createdAt = Date()
        self.lastModified = Date()
    }
    
    /**
     * Add earned Coinz to wallet and track learning time
     */
    mutating func earnCoinz(_ amount: Int, from appConfig: AppCoinzConfig, learningMinutes: Int = 0) {
        currentBalance += amount
        totalEarned += amount
        dailyEarned += amount
        
        // Track learning time if this is a learning app
        if appConfig.category == .learning && learningMinutes > 0 {
            dailyLearningMinutes += learningMinutes
            totalLearningMinutes += learningMinutes
        }
        
        lastModified = Date()
    }
    
    /**
     * Spend Coinz from wallet (returns false if insufficient balance)
     */
    mutating func spendCoinz(_ amount: Int, for appConfig: AppCoinzConfig) -> Bool {
        guard amount <= currentBalance else { return false }
        
        currentBalance -= amount
        totalSpent += amount
        dailySpent += amount
        lastModified = Date()
        return true
    }
    
    /**
     * Check if user can afford to spend on a reward app AND has met minimum learning requirement
     */
    func canAfford(minutesFor appConfig: AppCoinzConfig) -> Bool {
        guard appConfig.category == .reward else { return true }
        
        let costPerMinute = abs(appConfig.coinzRate)
        let hasEnoughCoinz = currentBalance >= costPerMinute
        let hasMetLearningRequirement = dailyLearningMinutes >= minimumDailyLearningMinutes
        
        return hasEnoughCoinz && hasMetLearningRequirement
    }
    
    /**
     * Calculate maximum affordable minutes considering both Coinz and daily time limits
     */
    func affordableMinutes(for appConfig: AppCoinzConfig) -> Int {
        guard appConfig.category == .reward else { return Int.max }
        
        let costPerMinute = abs(appConfig.coinzRate)
        let hasMetLearningRequirement = dailyLearningMinutes >= minimumDailyLearningMinutes
        
        if !hasMetLearningRequirement {
            return 0  // Cannot use reward apps until learning requirement is met
        }
        
        // Calculate minutes affordable with Coinz
        let coinzAffordableMinutes = costPerMinute > 0 ? currentBalance / costPerMinute : 0
        
        // Calculate remaining daily time limit
        let usedToday = dailyRewardUsage[appConfig.bundleID] ?? 0
        let remainingDailyLimit: Int
        
        if appConfig.dailyTimeLimit > 0 {
            remainingDailyLimit = max(0, appConfig.dailyTimeLimit - usedToday)
        } else {
            remainingDailyLimit = Int.max  // No daily limit
        }
        
        // Return the minimum of Coinz-affordable and time-limit-allowed
        return min(coinzAffordableMinutes, remainingDailyLimit)
    }
    
    /**
     * Add reward app usage time (for tracking daily limits)
     */
    mutating func addRewardUsage(for bundleID: String, minutes: Int) {
        let currentUsage = dailyRewardUsage[bundleID] ?? 0
        dailyRewardUsage[bundleID] = currentUsage + minutes
        lastModified = Date()
    }
    
    /**
     * Get remaining time for a specific reward app today
     */
    func getRemainingDailyTime(for appConfig: AppCoinzConfig) -> Int {
        guard appConfig.category == .reward else { return Int.max }
        
        if appConfig.dailyTimeLimit <= 0 {
            return Int.max  // No daily limit
        }
        
        let usedToday = dailyRewardUsage[appConfig.bundleID] ?? 0
        return max(0, appConfig.dailyTimeLimit - usedToday)
    }
    
    /**
     * Check if user can purchase time (considering both Coinz and time limits)
     */
    func canPurchaseTime(for appConfig: AppCoinzConfig, minutes: Int) -> (canPurchase: Bool, reason: String?) {
        guard appConfig.category == .reward else { return (true, nil) }
        
        // Check learning requirement
        if !hasMetDailyLearningRequirement {
            return (false, "Complete daily learning goal first")
        }
        
        // Check Coinz balance
        let totalCost = abs(appConfig.coinzRate) * minutes
        if currentBalance < totalCost {
            return (false, "Not enough Coinz (need \(totalCost), have \(currentBalance))")
        }
        
        // Check daily time limit
        let remainingTime = getRemainingDailyTime(for: appConfig)
        if minutes > remainingTime {
            if remainingTime == 0 {
                return (false, "Daily time limit reached for this app")
            } else {
                return (false, "Only \(remainingTime) minutes remaining today")
            }
        }
        
        return (true, nil)
    }
    
    /**
     * Reset daily counters if needed
     */
    mutating func resetDailyCountersIfNeeded() {
        let calendar = Calendar.current
        if !calendar.isDate(lastResetDate, inSameDayAs: Date()) {
            // Store yesterday's balance before reset for carryover display
            let yesterdayBalance = currentBalance
            
            dailyEarned = 0
            dailySpent = 0
            dailyLearningMinutes = 0  // Reset daily learning time
            dailyRewardUsage = [:]    // Reset daily reward app usage
            lastResetDate = Date()
            lastModified = Date()
            
            // Note: currentBalance is NOT reset - it carries over to the next day
            // This implements the cumulative Coinz system
        }
    }
    
    /**
     * Get the balance that carried over from previous days
     */
    var carryoverBalance: Int {
        return currentBalance - dailyEarned + dailySpent
    }
    
    /**
     * Check if user has any carryover balance from previous days
     */
    var hasCarryoverBalance: Bool {
        return carryoverBalance > 0
    }
    
    /**
     * Check if minimum daily learning requirement is met
     */
    var hasMetDailyLearningRequirement: Bool {
        return dailyLearningMinutes >= minimumDailyLearningMinutes
    }
    
    /**
     * Get remaining learning minutes needed to unlock reward apps
     */
    var remainingLearningMinutesRequired: Int {
        return max(0, minimumDailyLearningMinutes - dailyLearningMinutes)
    }
    
    /**
     * Get learning progress as a percentage (0.0 to 1.0)
     */
    var learningProgressPercentage: Double {
        guard minimumDailyLearningMinutes > 0 else { return 1.0 }
        return min(Double(dailyLearningMinutes) / Double(minimumDailyLearningMinutes), 1.0)
    }
    
    /**
     * Create from CloudKit record
     */
    init(from record: CKRecord) throws {
        guard let userID = record["userID"] as? String,
              let deviceID = record["deviceID"] as? String,
              let currentBalance = record["currentBalance"] as? Int,
              let totalEarned = record["totalEarned"] as? Int,
              let totalSpent = record["totalSpent"] as? Int,
              let dailyEarned = record["dailyEarned"] as? Int,
              let dailySpent = record["dailySpent"] as? Int,
              let lastResetDate = record["lastResetDate"] as? Date,
              let createdAt = record["createdAt"] as? Date,
              let lastModified = record["lastModified"] as? Date else {
            throw CoinzError.invalidRecord
        }
        
        self.id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        self.userID = userID
        self.deviceID = deviceID
        self.currentBalance = currentBalance
        self.totalEarned = totalEarned
        self.totalSpent = totalSpent
        self.dailyEarned = dailyEarned
        self.dailySpent = dailySpent
        self.dailyLearningMinutes = record["dailyLearningMinutes"] as? Int ?? 0
        self.totalLearningMinutes = record["totalLearningMinutes"] as? Int ?? 0
        self.dailyRewardUsage = record["dailyRewardUsage"] as? [String: Int] ?? [:]
        self.minimumDailyLearningMinutes = record["minimumDailyLearningMinutes"] as? Int ?? 15
        self.lastResetDate = lastResetDate
        self.createdAt = createdAt
        self.lastModified = lastModified
    }
    
    /**
     * Convert to CloudKit record
     */
    func toCloudKitRecord(in zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: "CoinzWallet", recordID: recordID)
        
        record["userID"] = userID
        record["deviceID"] = deviceID
        record["currentBalance"] = currentBalance
        record["totalEarned"] = totalEarned
        record["totalSpent"] = totalSpent
        record["dailyEarned"] = dailyEarned
        record["dailySpent"] = dailySpent
        record["dailyLearningMinutes"] = dailyLearningMinutes
        record["totalLearningMinutes"] = totalLearningMinutes
        record["dailyRewardUsage"] = dailyRewardUsage
        record["minimumDailyLearningMinutes"] = minimumDailyLearningMinutes
        record["lastResetDate"] = lastResetDate
        record["createdAt"] = createdAt
        record["lastModified"] = Date()
        
        return record
    }
}

/**
 * Transaction record for Coinz earning/spending
 */
struct CoinzTransaction: Identifiable, Codable {
    let id: UUID
    let walletID: UUID
    let appBundleID: String
    let appDisplayName: String
    let transactionType: TransactionType
    let coinzAmount: Int                // Positive for earning, negative for spending
    let timeSpentMinutes: Int
    let timestamp: Date
    var isValid: Bool                   // For transaction validation
    
    enum TransactionType: String, CaseIterable {
        case earned = "earned"
        case spent = "spent"
        case bonus = "bonus"           // Parent-given bonus
        case penalty = "penalty"       // Parent-imposed penalty
        case adjustment = "adjustment" // Parent balance adjustment (reset)
        
        var displayName: String {
            switch self {
            case .earned:
                return "Earned"
            case .spent:
                return "Spent"
            case .bonus:
                return "Bonus"
            case .penalty:
                return "Penalty"
            case .adjustment:
                return "Adjustment"
            }
        }
        
        var iconName: String {
            switch self {
            case .earned:
                return "plus.circle.fill"
            case .spent:
                return "minus.circle.fill"
            case .bonus:
                return "gift.fill"
            case .penalty:
                return "xmark.circle.fill"
            case .adjustment:
                return "slider.horizontal.3"
            }
        }
        
        var color: String {
            switch self {
            case .earned, .bonus:
                return "green"
            case .spent, .penalty:
                return "red"
            case .adjustment:
                return "blue"
            }
        }
    }
    
    init(walletID: UUID, appBundleID: String, appDisplayName: String, 
         transactionType: TransactionType, coinzAmount: Int, timeSpentMinutes: Int) {
        self.id = UUID()
        self.walletID = walletID
        self.appBundleID = appBundleID
        self.appDisplayName = appDisplayName
        self.transactionType = transactionType
        self.coinzAmount = coinzAmount
        self.timeSpentMinutes = timeSpentMinutes
        self.timestamp = Date()
        self.isValid = true
    }
    
    /**
     * Create from CloudKit record
     */
    init(from record: CKRecord) throws {
        guard let walletIDString = record["walletID"] as? String,
              let walletID = UUID(uuidString: walletIDString),
              let appBundleID = record["appBundleID"] as? String,
              let appDisplayName = record["appDisplayName"] as? String,
              let transactionTypeString = record["transactionType"] as? String,
              let transactionType = TransactionType(rawValue: transactionTypeString),
              let coinzAmount = record["coinzAmount"] as? Int,
              let timeSpentMinutes = record["timeSpentMinutes"] as? Int,
              let timestamp = record["timestamp"] as? Date,
              let isValid = record["isValid"] as? Bool else {
            throw CoinzError.invalidRecord
        }
        
        self.id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        self.walletID = walletID
        self.appBundleID = appBundleID
        self.appDisplayName = appDisplayName
        self.transactionType = transactionType
        self.coinzAmount = coinzAmount
        self.timeSpentMinutes = timeSpentMinutes
        self.timestamp = timestamp
        self.isValid = isValid
    }
    
    /**
     * Convert to CloudKit record
     */
    func toCloudKitRecord(in zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: "CoinzTransaction", recordID: recordID)
        
        record["walletID"] = walletID.uuidString
        record["appBundleID"] = appBundleID
        record["appDisplayName"] = appDisplayName
        record["transactionType"] = transactionType.rawValue
        record["coinzAmount"] = coinzAmount
        record["timeSpentMinutes"] = timeSpentMinutes
        record["timestamp"] = timestamp
        record["isValid"] = isValid
        
        return record
    }
}

/**
 * Learning goal with Coinz rewards
 */
struct CoinzGoal: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let targetCoinz: Int
    let bonusCoinz: Int                 // Bonus for completing goal
    let appBundleIDs: [String]          // Specific apps for this goal
    var progress: Int
    var isCompleted: Bool
    let startDate: Date
    let endDate: Date
    let createdBy: String               // Parent user ID
    var isActive: Bool
    
    init(title: String, description: String, targetCoinz: Int, bonusCoinz: Int, 
         appBundleIDs: [String], endDate: Date, createdBy: String) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.targetCoinz = targetCoinz
        self.bonusCoinz = bonusCoinz
        self.appBundleIDs = appBundleIDs
        self.progress = 0
        self.isCompleted = false
        self.startDate = Date()
        self.endDate = endDate
        self.createdBy = createdBy
        self.isActive = true
    }
    
    /**
     * Update progress towards goal
     */
    mutating func updateProgress(_ earnedCoinz: Int) -> Bool {
        progress += earnedCoinz
        if progress >= targetCoinz && !isCompleted {
            isCompleted = true
            return true // Goal completed
        }
        return false
    }
    
    /**
     * Calculate completion percentage
     */
    var completionPercentage: Double {
        guard targetCoinz > 0 else { return 0 }
        return min(Double(progress) / Double(targetCoinz), 1.0)
    }
    
    /**
     * Check if goal is expired
     */
    var isExpired: Bool {
        return Date() > endDate
    }
}

// MARK: - Predefined App Configurations

/**
 * Predefined learning apps with their default configurations
 */
struct PredefinedApps {
    static let learningApps: [AppCoinzConfig] = [
        AppCoinzConfig(bundleID: "com.khanacademy.khanacademykids", displayName: "Khan Academy Kids", category: .learning),
        AppCoinzConfig(bundleID: "org.scratch.scratchjr", displayName: "Scratch Jr", category: .learning),
        AppCoinzConfig(bundleID: "com.flashmath.app", displayName: "FlashMath", category: .learning),
        AppCoinzConfig(bundleID: "com.duolingo.duolingoapp", displayName: "Duolingo", category: .learning),
        AppCoinzConfig(bundleID: "com.apple.swift.playgrounds", displayName: "Swift Playgrounds", category: .learning),
        AppCoinzConfig(bundleID: "com.brainpop.brainpopjr", displayName: "BrainPOP Jr.", category: .learning),
        AppCoinzConfig(bundleID: "com.tinybop.thehuman", displayName: "The Human Body", category: .learning),
        AppCoinzConfig(bundleID: "com.tynker.junior", displayName: "Tynker Junior", category: .learning)
    ]
    
    static let rewardApps: [AppCoinzConfig] = [
        AppCoinzConfig(bundleID: "com.google.ios.youtube", displayName: "YouTube", category: .reward),
        AppCoinzConfig(bundleID: "com.google.ios.youtubekids", displayName: "YouTube Kids", category: .reward),
        AppCoinzConfig(bundleID: "com.king.candycrushsaga", displayName: "Candy Crush Saga", category: .reward),
        AppCoinzConfig(bundleID: "com.n3twork.tetris", displayName: "Tetris", category: .reward),
        AppCoinzConfig(bundleID: "com.rovio.angrybirds", displayName: "Angry Birds", category: .reward),
        AppCoinzConfig(bundleID: "com.disney.disneyplus", displayName: "Disney+", category: .reward),
        AppCoinzConfig(bundleID: "com.netflix.netflix", displayName: "Netflix", category: .reward),
        AppCoinzConfig(bundleID: "com.minecraft.minecraftpe", displayName: "Minecraft", category: .reward)
    ]
    
    /**
     * Get default configuration for a bundle ID
     */
    static func getDefaultConfig(for bundleID: String) -> AppCoinzConfig? {
        return (learningApps + rewardApps).first { $0.bundleID == bundleID }
    }
    
    /**
     * Create custom rates based on parent priorities
     */
    static func createCustomLearningRates() -> [String: Int] {
        return [
            "com.khanacademy.khanacademykids": 1,  // Standard rate
            "com.flashmath.app": 3,                // Higher value for math
            "org.scratch.scratchjr": 5,            // Highest value for coding
            "com.duolingo.duolingoapp": 2,         // Good for language learning
            "com.apple.swift.playgrounds": 5       // Highest for advanced coding
        ]
    }
    
    /**
     * Create custom spending rates for reward apps
     */
    static func createCustomRewardRates() -> [String: Int] {
        return [
            "com.google.ios.youtubekids": -5,      // Expensive to discourage overuse
            "com.king.candycrushsaga": -3,         // Moderate cost
            "com.n3twork.tetris": -2,              // Lower cost for puzzle games
            "com.minecraft.minecraftpe": -4,       // Higher cost for engaging games
            "com.disney.disneyplus": -6            // Highest cost for streaming
        ]
    }
}

// MARK: - Error Handling

/**
 * Coinz system specific errors
 */
enum CoinzError: Error, LocalizedError {
    case insufficientBalance
    case minimumLearningTimeNotMet
    case invalidAppConfig
    case invalidRecord
    case transactionFailed
    case goalNotFound
    case walletNotFound
    case appNotConfigured
    case parentalControlRequired
    
    var errorDescription: String? {
        switch self {
        case .insufficientBalance:
            return "💰 Not enough Coinz!\n\nEarn more Coinz by using learning apps to unlock this reward app."
        case .minimumLearningTimeNotMet:
            return "📚 Learning time required!\n\nComplete your daily learning time requirement before accessing reward apps."
        case .invalidAppConfig:
            return "⚙️ Invalid app configuration.\n\nPlease contact your parent to fix the app settings."
        case .invalidRecord:
            return "📱 Data sync error.\n\nPlease check your internet connection and try again."
        case .transactionFailed:
            return "💳 Transaction failed.\n\nPlease try again or contact support."
        case .goalNotFound:
            return "🎯 Goal not found.\n\nThe learning goal may have been removed or expired."
        case .walletNotFound:
            return "👛 Wallet not found.\n\nPlease restart the app to initialize your Coinz wallet."
        case .appNotConfigured:
            return "📋 App not configured.\n\nThis app needs to be set up by a parent first."
        case .parentalControlRequired:
            return "👨‍👩‍👧‍👦 Parent permission required.\n\nAsk your parent to configure this app's Coinz settings."
        }
    }
}