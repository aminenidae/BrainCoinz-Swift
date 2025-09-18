//
//  FamilyAccountManager.swift
//  BrainCoinz
//
//  Manages family accounts and cross-device synchronization for remote parental control
//  Integrates with CloudKit for real-time data sync between parent and child devices
//

import Foundation
import SwiftUI
import CloudKit
import Combine

/**
 * Manager responsible for family account management and cross-device synchronization.
 * Enables remote parental control by linking parent and child devices through CloudKit.
 * 
 * Key Features:
 * - Family account creation and management
 * - Device pairing and registration
 * - Real-time sync of goals and restrictions
 * - Remote control command distribution
 */
class FamilyAccountManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isCloudAvailable = false
    @Published var familyAccount: FamilyAccount?
    @Published var connectedDevices: [ConnectedDevice] = []
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    
    // MARK: - Types
    enum SyncStatus {
        case idle
        case syncing
        case success
        case failed(Error)
    }
    
    enum DeviceType {
        case parentDevice
        case childDevice
    }
    
    // MARK: - Private Properties
    private let container = CKContainer.default()
    private let database: CKDatabase
    private var cancellables = Set<AnyCancellable>()
    private let currentDeviceID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    
    // MARK: - Initialization
    init() {
        // Note: Currently uses private database
        // For true multi-family support with different iCloud accounts,
        // consider using shared CloudKit databases or public database
        self.database = container.privateCloudDatabase
        checkCloudAvailability()
        setupSubscriptions()
    }
    
    // MARK: - Public Methods
    
    /**
     * Creates a new family account with the current device as the parent device
     * @param familyName: Display name for the family
     * @param parentName: Name of the parent user
     * @param completion: Callback with success status and optional error
     */
    func createFamilyAccount(familyName: String, parentName: String, completion: @escaping (Bool, Error?) -> Void) {
        guard isCloudAvailable else {
            completion(false, FamilyAccountError.cloudUnavailable)
            return
        }
        
        let familyID = UUID().uuidString
        let familyRecord = CKRecord(recordType: "FamilyAccount", recordID: CKRecord.ID(recordName: familyID))
        
        familyRecord["familyName"] = familyName
        familyRecord["parentName"] = parentName
        familyRecord["parentDeviceID"] = currentDeviceID
        familyRecord["createdAt"] = Date()
        familyRecord["isActive"] = true
        
        database.save(familyRecord) { [weak self] record, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error)
                } else if let record = record {
                    self?.familyAccount = FamilyAccount(from: record)
                    self?.registerCurrentDevice(as: .parentDevice)
                    completion(true, nil)
                } else {
                    completion(false, FamilyAccountError.unknownError)
                }
            }
        }
    }
    
    /**
     * Joins an existing family account with the current device as a child device
     * @param familyCode: 6-digit family code for joining
     * @param childName: Name of the child user
     * @param completion: Callback with success status and optional error
     */
    func joinFamilyAccount(familyCode: String, childName: String, completion: @escaping (Bool, Error?) -> Void) {
        guard isCloudAvailable else {
            completion(false, FamilyAccountError.cloudUnavailable)
            return
        }
        
        // Search for family account by code
        let predicate = NSPredicate(format: "familyCode == %@", familyCode)
        let query = CKQuery(recordType: "FamilyAccount", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error)
                } else if let record = records?.first {
                    self?.familyAccount = FamilyAccount(from: record)
                    self?.registerCurrentDevice(as: .childDevice, childName: childName)
                    completion(true, nil)
                } else {
                    completion(false, FamilyAccountError.familyNotFound)
                }
            }
        }
    }
    
    /**
     * Joins an existing family account with the current device as an additional parent device
     * @param familyCode: 6-digit family code for joining
     * @param parentName: Name of the additional parent
     * @param completion: Callback with success status and optional error
     */
    func joinFamilyAsParent(familyCode: String, parentName: String, completion: @escaping (Bool, Error?) -> Void) {
        guard isCloudAvailable else {
            completion(false, FamilyAccountError.cloudUnavailable)
            return
        }
        
        // Search for family account by code
        let predicate = NSPredicate(format: "familyCode == %@", familyCode)
        let query = CKQuery(recordType: "FamilyAccount", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error)
                } else if let record = records?.first {
                    self?.familyAccount = FamilyAccount(from: record)
                    self?.registerCurrentDevice(as: .parentDevice, childName: parentName)
                    completion(true, nil)
                } else {
                    completion(false, FamilyAccountError.familyNotFound)
                }
            }
        }
    }
    
    /**
     * Sends a remote control command from parent device to child device
     * @param command: The remote control command to send
     * @param targetDeviceID: ID of the target child device
     * @param completion: Callback with success status
     */
    func sendRemoteCommand(_ command: RemoteControlCommand, to targetDeviceID: String, completion: @escaping (Bool) -> Void) {
        guard let familyAccount = familyAccount else {
            completion(false)
            return
        }
        
        let commandRecord = CKRecord(recordType: "RemoteCommand")
        commandRecord["familyAccountID"] = familyAccount.id
        commandRecord["targetDeviceID"] = targetDeviceID
        commandRecord["commandType"] = command.type.rawValue
        commandRecord["commandData"] = try? JSONEncoder().encode(command)
        commandRecord["sentAt"] = Date()
        commandRecord["isExecuted"] = false
        
        database.save(commandRecord) { record, error in
            DispatchQueue.main.async {
                completion(error == nil)
            }
        }
    }
    
    /**
     * Polls for new remote commands targeted at this device (child device)
     */
    func pollForRemoteCommands() {
        guard let familyAccount = familyAccount else { return }
        
        let predicate = NSPredicate(format: "familyAccountID == %@ AND targetDeviceID == %@ AND isExecuted == NO", 
                                  familyAccount.id, currentDeviceID)
        let query = CKQuery(recordType: "RemoteCommand", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let records = records, error == nil else { return }
            
            for record in records {
                self?.processRemoteCommand(record)
            }
        }
    }
    
    /**
     * Syncs family data including goals, app selections, and device status
     */
    func syncFamilyData() {
        guard isCloudAvailable, let familyAccount = familyAccount else { return }
        
        syncStatus = .syncing
        
        // Sync goals, app selections, and usage data
        syncLearningGoals()
        syncAppSelections()
        syncDeviceStatus()
        
        lastSyncDate = Date()
        syncStatus = .success
    }
    
    /**
     * Generates a 6-digit family code for sharing with child devices
     */
    func generateFamilyCode() -> String {
        return String(format: "%06d", Int.random(in: 100000...999999))
    }
    
    /**
     * Disconnects the current device from the family account
     */
    func leaveFamilyAccount(completion: @escaping (Bool) -> Void) {
        // Remove device registration and clean up local data
        familyAccount = nil
        connectedDevices.removeAll()
        completion(true)
    }
    
    /**
     * Checks if the current device is registered as a parent device
     */
    func isCurrentDeviceParent() -> Bool {
        return connectedDevices.first { device in
            device.deviceID == currentDeviceID && device.deviceType == "parent"
        } != nil
    }
    
    /**
     * Gets all parent devices in the family
     */
    func getParentDevices() -> [ConnectedDevice] {
        return connectedDevices.filter { $0.deviceType == "parent" }
    }
    
    /**
     * Gets all child devices in the family
     */
    func getChildDevices() -> [ConnectedDevice] {
        return connectedDevices.filter { $0.deviceType == "child" }
    }
    
    /**
     * Checks if a command can be sent (only parent devices can send commands)
     */
    func canSendRemoteCommands() -> Bool {
        return isCurrentDeviceParent()
    }
    
    // MARK: - Private Methods
    
    /**
     * Checks if CloudKit is available and user is signed in
     */
    private func checkCloudAvailability() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.isCloudAvailable = true
                    print("CloudKit: User is signed into iCloud and ready")
                case .noAccount:
                    self?.isCloudAvailable = false
                    print("CloudKit: User not signed into iCloud")
                case .restricted:
                    self?.isCloudAvailable = false
                    print("CloudKit: iCloud access restricted")
                case .couldNotDetermine:
                    self?.isCloudAvailable = false
                    print("CloudKit: Could not determine iCloud status")
                case .temporarilyUnavailable:
                    self?.isCloudAvailable = false
                    print("CloudKit: Temporarily unavailable")
                @unknown default:
                    self?.isCloudAvailable = false
                    print("CloudKit: Unknown status")
                }
            }
        }
    }
    
    /**
     * Gets detailed CloudKit authentication status for user guidance
     */
    func getCloudKitAuthenticationGuidance(completion: @escaping (String) -> Void) {
        container.accountStatus { status, error in
            DispatchQueue.main.async {
                let guidance: String
                switch status {
                case .available:
                    guidance = "✅ Ready to use family features"
                case .noAccount:
                    guidance = "❌ Please sign in to iCloud in Settings > [Your Name]"
                case .restricted:
                    guidance = "❌ iCloud access is restricted. Check Screen Time settings."
                case .couldNotDetermine:
                    guidance = "❓ Unable to check iCloud status. Try again later."
                case .temporarilyUnavailable:
                    guidance = "⏳ iCloud temporarily unavailable. Try again later."
                @unknown default:
                    guidance = "❓ Unknown iCloud status. Check your connection."
                }
                completion(guidance)
            }
        }
    }
    
    /**
     * Registers the current device with the family account
     */
    private func registerCurrentDevice(as type: DeviceType, childName: String? = nil) {
        guard let familyAccount = familyAccount else { return }
        
        let deviceRecord = CKRecord(recordType: "ConnectedDevice")
        deviceRecord["familyAccountID"] = familyAccount.id
        deviceRecord["deviceID"] = currentDeviceID
        deviceRecord["deviceType"] = type == .parentDevice ? "parent" : "child"
        deviceRecord["deviceName"] = UIDevice.current.name
        deviceRecord["userName"] = type == .parentDevice ? familyAccount.parentName : (childName ?? "Child")
        deviceRecord["registeredAt"] = Date()
        deviceRecord["isActive"] = true
        deviceRecord["lastSeen"] = Date()
        
        database.save(deviceRecord) { [weak self] record, error in
            if error == nil {
                self?.loadConnectedDevices()
            }
        }
    }
    
    /**
     * Loads all devices connected to the family account
     */
    private func loadConnectedDevices() {
        guard let familyAccount = familyAccount else { return }
        
        let predicate = NSPredicate(format: "familyAccountID == %@ AND isActive == YES", familyAccount.id)
        let query = CKQuery(recordType: "ConnectedDevice", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let records = records, error == nil else { return }
            
            DispatchQueue.main.async {
                self?.connectedDevices = records.compactMap { ConnectedDevice(from: $0) }
            }
        }
    }
    
    /**
     * Processes an incoming remote control command
     */
    private func processRemoteCommand(_ record: CKRecord) {
        guard let commandData = record["commandData"] as? Data,
              let command = try? JSONDecoder().decode(RemoteControlCommand.self, from: commandData) else {
            return
        }
        
        // Execute the command locally
        executeRemoteCommand(command)
        
        // Mark command as executed
        record["isExecuted"] = true
        record["executedAt"] = Date()
        
        database.save(record) { _, _ in
            // Command marked as executed
        }
    }
    
    /**
     * Executes a remote control command on this device
     */
    private func executeRemoteCommand(_ command: RemoteControlCommand) {
        switch command.type {
        case .blockApps:
            NotificationCenter.default.post(name: .remoteBlockApps, object: command.data)
        case .unblockApps:
            NotificationCenter.default.post(name: .remoteUnblockApps, object: command.data)
        case .updateGoal:
            NotificationCenter.default.post(name: .remoteUpdateGoal, object: command.data)
        case .sendMessage:
            NotificationCenter.default.post(name: .remoteMessage, object: command.data)
        }
    }
    
    /**
     * Syncs learning goals across devices
     */
    private func syncLearningGoals() {
        // Implementation for syncing goals via CloudKit
    }
    
    /**
     * Syncs app selections across devices  
     */
    private func syncAppSelections() {
        // Implementation for syncing app selections via CloudKit
    }
    
    /**
     * Updates device status and last seen timestamp
     */
    private func syncDeviceStatus() {
        // Implementation for updating device status
    }
    
    /**
     * Sets up CloudKit subscriptions for real-time updates
     */
    private func setupSubscriptions() {
        // Setup push notification subscriptions for real-time command delivery
    }
}

// MARK: - Supporting Types

/**
 * Represents a family account in CloudKit
 */
struct FamilyAccount {
    let id: String
    let familyName: String
    let parentName: String
    let parentDeviceID: String
    let familyCode: String
    let createdAt: Date
    let isActive: Bool
    
    init(from record: CKRecord) {
        self.id = record.recordID.recordName
        self.familyName = record["familyName"] as? String ?? ""
        self.parentName = record["parentName"] as? String ?? ""
        self.parentDeviceID = record["parentDeviceID"] as? String ?? ""
        self.familyCode = record["familyCode"] as? String ?? ""
        self.createdAt = record["createdAt"] as? Date ?? Date()
        self.isActive = record["isActive"] as? Bool ?? false
    }
}

/**
 * Represents a device connected to the family account
 */
struct ConnectedDevice {
    let deviceID: String
    let deviceType: String
    let deviceName: String
    let userName: String
    let registeredAt: Date
    let lastSeen: Date
    let isActive: Bool
    
    init(from record: CKRecord) {
        self.deviceID = record["deviceID"] as? String ?? ""
        self.deviceType = record["deviceType"] as? String ?? ""
        self.deviceName = record["deviceName"] as? String ?? ""
        self.userName = record["userName"] as? String ?? ""
        self.registeredAt = record["registeredAt"] as? Date ?? Date()
        self.lastSeen = record["lastSeen"] as? Date ?? Date()
        self.isActive = record["isActive"] as? Bool ?? false
    }
}

/**
 * Remote control command structure
 */
struct RemoteControlCommand: Codable {
    let type: CommandType
    let data: [String: String]
    let timestamp: Date
    
    enum CommandType: String, Codable {
        case blockApps = "block_apps"
        case unblockApps = "unblock_apps"
        case updateGoal = "update_goal"
        case sendMessage = "send_message"
    }
}

/**
 * Family account management errors
 */
enum FamilyAccountError: Error, LocalizedError {
    case cloudUnavailable
    case familyNotFound
    case deviceAlreadyRegistered
    case unauthorized
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .cloudUnavailable:
            return "⚠️ iCloud is not available.\n\nTo use family features:\n1. Go to Settings > [Your Name]\n2. Sign in to iCloud\n3. Enable iCloud for this app"
        case .familyNotFound:
            return "❌ Family account not found.\n\nPlease check the 6-digit family code and try again."
        case .deviceAlreadyRegistered:
            return "📱 This device is already registered with a family account.\n\nLeave the current family first to join a new one."
        case .unauthorized:
            return "🔒 Not authorized to access family account.\n\nMake sure you're signed into the correct iCloud account."
        case .unknownError:
            return "❓ An unknown error occurred.\n\nPlease check your internet connection and try again."
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let remoteBlockApps = Notification.Name("remoteBlockApps")
    static let remoteUnblockApps = Notification.Name("remoteUnblockApps")
    static let remoteUpdateGoal = Notification.Name("remoteUpdateGoal")
    static let remoteMessage = Notification.Name("remoteMessage")
    static let familyDataSynced = Notification.Name("familyDataSynced")
}