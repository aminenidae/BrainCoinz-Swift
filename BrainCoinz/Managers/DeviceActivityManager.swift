//
//  DeviceActivityManager.swift
//  BrainCoinz
//
//  Manages device activity monitoring to track app usage and learning progress
//  Integrates with Apple's DeviceActivity framework for real-time usage tracking
//

import Foundation
import SwiftUI
import DeviceActivity
import FamilyControls
import CoreData

/**
 * Manager responsible for monitoring device activity and tracking app usage.
 * This class handles the setup and management of DeviceActivity monitors
 * to track learning app usage and determine when goals are met.
 */
class DeviceActivityManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isMonitoring = false
    @Published var currentLearningTime: TimeInterval = 0
    @Published var dailyGoalProgress: Double = 0.0
    @Published var lastUpdated = Date()
    
    // MARK: - Private Properties
    private let deviceActivityCenter = DeviceActivityCenter()
    private let monitorName = DeviceActivityName("BrainCoinzMonitor")
    private var currentGoal: LearningGoal?
    private var learningAppTokens: Set<ApplicationToken> = []
    
    // Core Data context
    private var viewContext: NSManagedObjectContext {
        return PersistenceController.shared.container.viewContext
    }
    
    // MARK: - Initialization
    init() {
        // Initialize will be called after Family Controls authorization
    }
    
    // MARK: - Public Methods
    
    /**
     * Initializes the DeviceActivity manager after Family Controls authorization
     */
    func initialize() {
        print("DeviceActivityManager initialized")
    }
    
    /**
     * Starts monitoring for a specific learning goal
     * @param goal: The LearningGoal to monitor
     * @param learningApps: Set of app tokens to monitor for learning
     */
    func startMonitoring(for goal: LearningGoal, learningApps: Set<ApplicationToken>) {
        guard !learningApps.isEmpty else {
            print("No learning apps to monitor")
            return
        }
        
        currentGoal = goal
        learningAppTokens = learningApps
        
        // Create schedule for daily monitoring (reset at midnight)
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        // Create event for monitoring app usage
        let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
            .learningAppUsage: DeviceActivityEvent(
                applications: learningApps,
                threshold: DateComponents(minute: 1) // Check every minute
            )
        ]
        
        do {
            try deviceActivityCenter.startMonitoring(
                monitorName,
                during: schedule,
                events: events
            )
            
            DispatchQueue.main.async {
                self.isMonitoring = true
            }
            
            print("Started monitoring \(learningApps.count) learning apps")
            
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }
    
    /**
     * Stops all current monitoring
     */
    func stopMonitoring() {
        deviceActivityCenter.stopMonitoring([monitorName])
        
        DispatchQueue.main.async {
            self.isMonitoring = false
            self.currentLearningTime = 0
            self.dailyGoalProgress = 0.0
        }
        
        print("Stopped monitoring")
    }
    
    /**
     * Updates learning time progress for the current goal
     * This method would typically be called from a DeviceActivity extension
     */
    func updateLearningProgress(additionalTime: TimeInterval) {
        guard let goal = currentGoal else { return }
        
        DispatchQueue.main.async {
            self.currentLearningTime += additionalTime
            self.lastUpdated = Date()
            
            // Calculate progress as percentage
            let targetMinutes = Double(goal.targetDurationMinutes)
            let currentMinutes = self.currentLearningTime / 60.0
            self.dailyGoalProgress = min(currentMinutes / targetMinutes, 1.0)
            
            // Check if goal is completed
            if self.dailyGoalProgress >= 1.0 {
                self.handleGoalCompletion()
            }
        }
        
        // Save usage session to Core Data
        saveUsageSession(duration: additionalTime)
    }
    
    /**
     * Gets the current daily learning time in minutes
     */
    func getCurrentLearningMinutes() -> Double {
        return currentLearningTime / 60.0
    }
    
    /**
     * Gets the remaining time needed to complete the goal
     */
    func getRemainingMinutes() -> Double {
        guard let goal = currentGoal else { return 0 }
        
        let targetMinutes = Double(goal.targetDurationMinutes)
        let currentMinutes = getCurrentLearningMinutes()
        return max(targetMinutes - currentMinutes, 0)
    }
    
    /**
     * Checks if the current goal is completed
     */
    func isGoalCompleted() -> Bool {
        return dailyGoalProgress >= 1.0
    }
    
    /**
     * Resets daily progress (typically called at midnight)
     */
    func resetDailyProgress() {
        DispatchQueue.main.async {
            self.currentLearningTime = 0
            self.dailyGoalProgress = 0.0
            self.lastUpdated = Date()
        }
        
        print("Daily progress reset")
    }
    
    /**
     * Gets usage statistics for a specific date range
     */
    func getUsageStatistics(from startDate: Date, to endDate: Date) -> [AppUsageSession] {
        let request: NSFetchRequest<AppUsageSession> = AppUsageSession.fetchRequest()
        request.predicate = NSPredicate(
            format: "startTime >= %@ AND startTime <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch usage statistics: \(error)")
            return []
        }
    }
    
    /**
     * Gets total learning time for today
     */
    func getTodayLearningTime() -> TimeInterval {
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? today
        
        let sessions = getUsageStatistics(from: startOfDay, to: endOfDay)
        return sessions.reduce(0) { $0 + $1.duration }
    }
    
    // MARK: - Private Methods
    
    /**
     * Handles when a learning goal is completed
     */
    private func handleGoalCompletion() {
        guard let goal = currentGoal else { return }
        
        print("Learning goal completed! Unlocking reward apps...")
        
        // Notify other managers about goal completion
        NotificationCenter.default.post(
            name: .goalCompleted,
            object: goal
        )
        
        // Update goal completion status
        goal.isActive = false
        saveContext()
    }
    
    /**
     * Saves a usage session to Core Data
     */
    private func saveUsageSession(duration: TimeInterval) {
        guard let goal = currentGoal,
              let user = goal.user else { return }
        
        let session = AppUsageSession(context: viewContext)
        session.sessionID = UUID()
        session.appBundleID = "multiple" // Could be enhanced to track individual apps
        session.startTime = Date().addingTimeInterval(-duration)
        session.endTime = Date()
        session.duration = duration
        session.user = user
        
        saveContext()
    }
    
    /**
     * Saves Core Data context
     */
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}

// MARK: - DeviceActivityEvent Extensions

extension DeviceActivityEvent.Name {
    static let learningAppUsage = DeviceActivityEvent.Name("learningAppUsage")
}

// MARK: - Notification Names

extension Notification.Name {
    static let goalCompleted = Notification.Name("goalCompleted")
    static let progressUpdated = Notification.Name("progressUpdated")
}

// MARK: - DeviceActivity Extension Support

/**
 * This protocol defines the interface for DeviceActivity extension communication
 * The actual extension would implement these methods
 */
protocol DeviceActivityExtensionInterface {
    func intervalDidStart(for activity: DeviceActivityName)
    func intervalDidEnd(for activity: DeviceActivityName)
    func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName)
    func intervalWillStartWarning(for activity: DeviceActivityName)
    func intervalWillEndWarning(for activity: DeviceActivityName)
}

/**
 * Helper struct for app usage data
 */
struct AppUsageData {
    let bundleID: String
    let appName: String
    let duration: TimeInterval
    let lastUsed: Date
}

// MARK: - Usage Statistics Helper

extension DeviceActivityManager {
    
    /**
     * Calculates weekly learning statistics
     */
    func getWeeklyStats() -> WeeklyStats {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        let sessions = getUsageStatistics(from: startOfWeek, to: today)
        let totalMinutes = sessions.reduce(0) { $0 + $1.duration } / 60.0
        let averageDaily = totalMinutes / 7.0
        
        return WeeklyStats(
            totalMinutes: totalMinutes,
            averageDailyMinutes: averageDaily,
            sessionsCount: sessions.count
        )
    }
}

struct WeeklyStats {
    let totalMinutes: Double
    let averageDailyMinutes: Double
    let sessionsCount: Int
}