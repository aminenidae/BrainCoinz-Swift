//
//  NotificationManager.swift
//  BrainCoinz
//
//  Manages push notifications for progress updates, goal completion, and reminders
//  Handles both local and remote notifications for parent/child communication
//

import Foundation
import SwiftUI
import UserNotifications

/**
 * Manager responsible for handling all notifications in the BrainCoinz app.
 * This includes progress updates, goal completion alerts, and reminder notifications
 * for both parents and children.
 */
class NotificationManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var notificationPermissionGranted = false
    @Published var pendingNotifications: [UNNotificationRequest] = []
    
    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // Notification Categories
    private let progressCategory = "PROGRESS_CATEGORY"
    private let goalCompletedCategory = "GOAL_COMPLETED_CATEGORY"
    private let reminderCategory = "REMINDER_CATEGORY"
    private let parentAlertCategory = "PARENT_ALERT_CATEGORY"
    
    // MARK: - Initialization
    override init() {
        super.init()
        notificationCenter.delegate = self
        setupNotificationCategories()
        setupNotificationObservers()
    }
    
    // MARK: - Public Methods
    
    /**
     * Requests notification permissions from the user
     */
    func requestPermissions() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.notificationPermissionGranted = granted
            }
            
            if let error = error {
                print("Notification permission error: \(error)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }
    }
    
    /**
     * Sends a progress update notification to the child
     * @param currentMinutes: Current learning time in minutes
     * @param targetMinutes: Target learning time in minutes
     * @param childName: Name of the child
     */
    func sendProgressUpdate(currentMinutes: Double, targetMinutes: Double, childName: String) {
        let progress = (currentMinutes / targetMinutes) * 100
        let remaining = max(targetMinutes - currentMinutes, 0)
        
        let content = UNMutableNotificationContent()
        content.title = "Great Progress, \(childName)!"
        content.body = String(format: "You've completed %.0f%% of your learning goal. Only %.0f minutes to go!", progress, remaining)
        content.sound = .default
        content.categoryIdentifier = progressCategory
        content.badge = NSNumber(value: Int(progress))
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "progress_\(UUID().uuidString)", content: content, trigger: trigger)
        
        scheduleNotification(request)
    }
    
    /**
     * Sends goal completion notification to both parent and child
     * @param childName: Name of the child who completed the goal
     * @param targetMinutes: The goal that was completed
     * @param rewardAppsCount: Number of reward apps unlocked
     */
    func sendGoalCompletionNotification(childName: String, targetMinutes: Int, rewardAppsCount: Int) {
        // Notification for child
        let childContent = UNMutableNotificationContent()
        childContent.title = "🎉 Goal Completed!"
        childContent.body = "Awesome job, \(childName)! You've earned access to your \(rewardAppsCount) reward apps!"
        childContent.sound = .default
        childContent.categoryIdentifier = goalCompletedCategory
        
        let childTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let childRequest = UNNotificationRequest(
            identifier: "goal_completed_child_\(UUID().uuidString)",
            content: childContent,
            trigger: childTrigger
        )
        
        // Notification for parent
        let parentContent = UNMutableNotificationContent()
        parentContent.title = "Child Goal Completed"
        parentContent.body = "\(childName) has completed their \(targetMinutes)-minute learning goal and unlocked reward apps."
        parentContent.sound = .default
        parentContent.categoryIdentifier = parentAlertCategory
        
        let parentTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let parentRequest = UNNotificationRequest(
            identifier: "goal_completed_parent_\(UUID().uuidString)",
            content: parentContent,
            trigger: parentTrigger
        )
        
        scheduleNotification(childRequest)
        scheduleNotification(parentRequest)
    }
    
    /**
     * Sends a reminder notification to encourage learning
     * @param childName: Name of the child
     * @param remainingMinutes: Minutes remaining to complete goal
     */
    func sendLearningReminder(childName: String, remainingMinutes: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Learning Time Reminder"
        content.body = String(format: "Hi \(childName)! You need %.0f more minutes of learning time to unlock your rewards.", remainingMinutes)
        content.sound = .default
        content.categoryIdentifier = reminderCategory
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "reminder_\(UUID().uuidString)", content: content, trigger: trigger)
        
        scheduleNotification(request)
    }
    
    /**
     * Schedules a daily reminder for learning goals
     * @param time: Time of day to send reminder (hour and minute)
     * @param childName: Name of the child
     */
    func scheduleDailyReminder(at time: DateComponents, for childName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Daily Learning Time"
        content.body = "Time to start your learning goals, \(childName)!"
        content.sound = .default
        content.categoryIdentifier = reminderCategory
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_reminder_\(childName)",
            content: content,
            trigger: trigger
        )
        
        scheduleNotification(request)
    }
    
    /**
     * Sends notification when reward apps are blocked again (daily reset)
     * @param childName: Name of the child
     */
    func sendDailyResetNotification(childName: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Day, New Goals!"
        content.body = "Good morning \(childName)! Complete your learning goals to unlock your reward apps again."
        content.sound = .default
        content.categoryIdentifier = reminderCategory
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "daily_reset_\(UUID().uuidString)", content: content, trigger: trigger)
        
        scheduleNotification(request)
    }
    
    /**
     * Sends notification when time limit is exceeded
     * @param childName: Name of the child
     * @param excessMinutes: Minutes over the limit
     */
    func sendTimeExceededNotification(childName: String, excessMinutes: Double) {
        let parentContent = UNMutableNotificationContent()
        parentContent.title = "Screen Time Alert"
        parentContent.body = String(format: "\(childName) has exceeded their screen time limit by %.0f minutes.", excessMinutes)
        parentContent.sound = .default
        parentContent.categoryIdentifier = parentAlertCategory
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "time_exceeded_\(UUID().uuidString)",
            content: parentContent,
            trigger: trigger
        )
        
        scheduleNotification(request)
    }
    
    /**
     * Cancels all pending notifications
     */
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        
        DispatchQueue.main.async {
            self.pendingNotifications.removeAll()
        }
    }
    
    /**
     * Cancels notifications for a specific child
     */
    func cancelNotifications(for childName: String) {
        notificationCenter.getPendingNotificationRequests { requests in
            let identifiersToCancel = requests
                .filter { $0.content.body.contains(childName) }
                .map { $0.identifier }
            
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
        }
    }
    
    /**
     * Gets all pending notifications
     */
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                self.pendingNotifications = requests
                completion(requests)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /**
     * Schedules a notification
     */
    private func scheduleNotification(_ request: UNNotificationRequest) {
        guard notificationPermissionGranted else {
            print("Notification permission not granted")
            return
        }
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            } else {
                print("Scheduled notification: \(request.identifier)")
            }
        }
    }
    
    /**
     * Sets up notification categories with actions
     */
    private func setupNotificationCategories() {
        // Progress category with "View Progress" action
        let viewProgressAction = UNNotificationAction(
            identifier: "VIEW_PROGRESS",
            title: "View Progress",
            options: [.foreground]
        )
        
        let progressCategory = UNNotificationCategory(
            identifier: self.progressCategory,
            actions: [viewProgressAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Goal completed category with "Open App" action
        let openAppAction = UNNotificationAction(
            identifier: "OPEN_APP",
            title: "Open App",
            options: [.foreground]
        )
        
        let goalCompletedCategory = UNNotificationCategory(
            identifier: self.goalCompletedCategory,
            actions: [openAppAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Reminder category with "Start Learning" action
        let startLearningAction = UNNotificationAction(
            identifier: "START_LEARNING",
            title: "Start Learning",
            options: [.foreground]
        )
        
        let reminderCategory = UNNotificationCategory(
            identifier: self.reminderCategory,
            actions: [startLearningAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Parent alert category
        let parentAlertCategory = UNNotificationCategory(
            identifier: self.parentAlertCategory,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([
            progressCategory,
            goalCompletedCategory,
            reminderCategory,
            parentAlertCategory
        ])
    }
    
    /**
     * Sets up notification observers for app events
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
            selector: #selector(handleProgressUpdated),
            name: .progressUpdated,
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
        guard let goal = notification.object as? LearningGoal,
              let user = goal.user else { return }
        
        let rewardAppsCount = goal.rewardApps?.count ?? 0
        sendGoalCompletionNotification(
            childName: user.name,
            targetMinutes: Int(goal.targetDurationMinutes),
            rewardAppsCount: rewardAppsCount
        )
    }
    
    /**
     * Handles progress update notification
     */
    @objc private func handleProgressUpdated(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let currentMinutes = userInfo["currentMinutes"] as? Double,
              let targetMinutes = userInfo["targetMinutes"] as? Double,
              let childName = userInfo["childName"] as? String else { return }
        
        sendProgressUpdate(
            currentMinutes: currentMinutes,
            targetMinutes: targetMinutes,
            childName: childName
        )
    }
    
    /**
     * Handles daily reset notification
     */
    @objc private func handleDailyReset(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let childName = userInfo["childName"] as? String else { return }
        
        sendDailyResetNotification(childName: childName)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    
    /**
     * Handles notification when app is in foreground
     */
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /**
     * Handles user interaction with notifications
     */
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        
        switch actionIdentifier {
        case "VIEW_PROGRESS":
            // Navigate to progress view
            NotificationCenter.default.post(name: .showProgress, object: nil)
        case "OPEN_APP":
            // Navigate to main app
            NotificationCenter.default.post(name: .openMainApp, object: nil)
        case "START_LEARNING":
            // Navigate to learning apps
            NotificationCenter.default.post(name: .startLearning, object: nil)
        default:
            break
        }
        
        completionHandler()
    }
}

// MARK: - Notification Names for Navigation

extension Notification.Name {
    static let showProgress = Notification.Name("showProgress")
    static let openMainApp = Notification.Name("openMainApp")
    static let startLearning = Notification.Name("startLearning")
}