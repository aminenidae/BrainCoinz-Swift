//
//  SharedFamilyModels.swift
//  BrainCoinz
//
//  Data models for SharedFamilyManager v3.0.0 multi-family support
//

import Foundation
import CloudKit

// MARK: - Shared Family Models

/**
 * Shared family record for cross-iCloud account families
 */
struct SharedFamily: Identifiable, Codable {
    let id: UUID
    let name: String
    let organizerName: String
    let organizerUserID: String
    let creationDate: Date
    let lastModified: Date
    var isActive: Bool
    
    // CloudKit properties
    var recordID: CKRecord.ID?
    var recordChangeTag: String?
    
    init(id: UUID = UUID(), name: String, organizerName: String, organizerUserID: String) {
        self.id = id
        self.name = name
        self.organizerName = organizerName
        self.organizerUserID = organizerUserID
        self.creationDate = Date()
        self.lastModified = Date()
        self.isActive = true
    }
    
    /**
     * Create from CloudKit record
     */
    init(from record: CKRecord) throws {
        guard let name = record["name"] as? String,
              let organizerName = record["organizerName"] as? String,
              let organizerUserID = record["organizerUserID"] as? String,
              let creationDate = record["creationDate"] as? Date,
              let lastModified = record["lastModified"] as? Date,
              let isActive = record["isActive"] as? Bool else {
            throw SharedFamilyError.invalidRecord
        }
        
        self.id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        self.name = name
        self.organizerName = organizerName
        self.organizerUserID = organizerUserID
        self.creationDate = creationDate
        self.lastModified = lastModified
        self.isActive = isActive
        self.recordID = record.recordID
        self.recordChangeTag = record.recordChangeTag
    }
    
    /**
     * Convert to CloudKit record
     */
    func toCloudKitRecord(in zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: "SharedFamily", recordID: recordID)
        
        record["name"] = name
        record["organizerName"] = organizerName
        record["organizerUserID"] = organizerUserID
        record["creationDate"] = creationDate
        record["lastModified"] = Date() // Always update when saving
        record["isActive"] = isActive
        
        return record
    }
}

/**
 * Family member with role and device information
 */
struct FamilyMember: Identifiable, Codable {
    let id: UUID
    let userID: String
    let name: String
    let email: String?
    let deviceID: String
    let deviceName: String
    var role: FamilyRole
    var isOnline: Bool
    var lastSeen: Date
    var joinedDate: Date
    var isCurrentUser: Bool = false
    
    // CloudKit properties
    var recordID: CKRecord.ID?
    
    init(userID: String, name: String, email: String? = nil, deviceID: String, deviceName: String, role: FamilyRole) {
        self.id = UUID()
        self.userID = userID
        self.name = name
        self.email = email
        self.deviceID = deviceID
        self.deviceName = deviceName
        self.role = role
        self.isOnline = true
        self.lastSeen = Date()
        self.joinedDate = Date()
    }
    
    /**
     * Create from CloudKit record
     */
    init(from record: CKRecord) throws {
        guard let userID = record["userID"] as? String,
              let name = record["name"] as? String,
              let deviceID = record["deviceID"] as? String,
              let deviceName = record["deviceName"] as? String,
              let roleString = record["role"] as? String,
              let role = FamilyRole(rawValue: roleString),
              let isOnline = record["isOnline"] as? Bool,
              let lastSeen = record["lastSeen"] as? Date,
              let joinedDate = record["joinedDate"] as? Date else {
            throw SharedFamilyError.invalidRecord
        }
        
        self.id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        self.userID = userID
        self.name = name
        self.email = record["email"] as? String
        self.deviceID = deviceID
        self.deviceName = deviceName
        self.role = role
        self.isOnline = isOnline
        self.lastSeen = lastSeen
        self.joinedDate = joinedDate
        self.recordID = record.recordID
    }
    
    /**
     * Convert to CloudKit record
     */
    func toCloudKitRecord(in zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: "FamilyMember", recordID: recordID)
        
        record["userID"] = userID
        record["name"] = name
        record["email"] = email
        record["deviceID"] = deviceID
        record["deviceName"] = deviceName
        record["role"] = role.rawValue
        record["isOnline"] = isOnline
        record["lastSeen"] = Date() // Update on save
        record["joinedDate"] = joinedDate
        
        return record
    }
}

/**
 * Family invitation for cross-account invites
 */
struct FamilyInvitation: Identifiable, Codable {
    let id: UUID
    let familyID: UUID
    let inviterName: String
    let inviteeEmail: String
    let inviteePhone: String?
    let role: FamilyRole
    var status: InvitationStatus
    let sentDate: Date
    let expiresAt: Date
    var acceptedDate: Date?
    
    // CloudKit properties
    var recordID: CKRecord.ID?
    
    init(familyID: UUID, inviterName: String, inviteeEmail: String, inviteePhone: String? = nil, role: FamilyRole) {
        self.id = UUID()
        self.familyID = familyID
        self.inviterName = inviterName
        self.inviteeEmail = inviteeEmail
        self.inviteePhone = inviteePhone
        self.role = role
        self.status = .pending
        self.sentDate = Date()
        self.expiresAt = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days
    }
    
    /**
     * Create from CloudKit record
     */
    init(from record: CKRecord) throws {
        guard let familyIDString = record["familyID"] as? String,
              let familyID = UUID(uuidString: familyIDString),
              let inviterName = record["inviterName"] as? String,
              let inviteeEmail = record["inviteeEmail"] as? String,
              let roleString = record["role"] as? String,
              let role = FamilyRole(rawValue: roleString),
              let statusString = record["status"] as? String,
              let status = InvitationStatus(rawValue: statusString),
              let sentDate = record["sentDate"] as? Date,
              let expiresAt = record["expiresAt"] as? Date else {
            throw SharedFamilyError.invalidRecord
        }
        
        self.id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        self.familyID = familyID
        self.inviterName = inviterName
        self.inviteeEmail = inviteeEmail
        self.inviteePhone = record["inviteePhone"] as? String
        self.role = role
        self.status = status
        self.sentDate = sentDate
        self.expiresAt = expiresAt
        self.acceptedDate = record["acceptedDate"] as? Date
        self.recordID = record.recordID
    }
    
    /**
     * Convert to CloudKit record
     */
    func toCloudKitRecord(in zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
        let record = CKRecord(recordType: "FamilyInvitation", recordID: recordID)
        
        record["familyID"] = familyID.uuidString
        record["inviterName"] = inviterName
        record["inviteeEmail"] = inviteeEmail
        record["inviteePhone"] = inviteePhone
        record["role"] = role.rawValue
        record["status"] = status.rawValue
        record["sentDate"] = sentDate
        record["expiresAt"] = expiresAt
        record["acceptedDate"] = acceptedDate
        
        return record
    }
}

// MARK: - Supporting Types

/**
 * Invitation status enumeration
 */
enum InvitationStatus: String, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending"
        case .accepted:
            return "Accepted"
        case .declined:
            return "Declined"
        case .expired:
            return "Expired"
        }
    }
}

/**
 * Family role enumeration with permissions
 */
enum FamilyRole: String, CaseIterable {
    case organizer = "organizer"     // Can invite/remove members, full control
    case parent = "parent"           // Can control children, limited admin
    case child = "child"             // Receives restrictions only
    case guardian = "guardian"       // Like parent but limited permissions
    
    var displayName: String {
        switch self {
        case .organizer:
            return "Organizer"
        case .parent:
            return "Parent"
        case .guardian:
            return "Guardian"
        case .child:
            return "Child"
        }
    }
    
    var canManageFamily: Bool {
        switch self {
        case .organizer, .parent:
            return true
        case .guardian, .child:
            return false
        }
    }
    
    var canSendCommands: Bool {
        switch self {
        case .organizer, .parent, .guardian:
            return true
        case .child:
            return false
        }
    }
}

// MARK: - Error Types

/**
 * Shared family management errors
 */
enum SharedFamilyError: Error, LocalizedError {
    case cloudUnavailable
    case noActiveFamily
    case invalidRecord
    case zoneCreationFailed
    case shareCreationFailed
    case invitationNotFound
    case memberNotFound
    case permissionDenied
    case networkError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .cloudUnavailable:
            return "iCloud is not available. Please check your internet connection and iCloud settings."
        case .noActiveFamily:
            return "No active family found. Please create or join a family first."
        case .invalidRecord:
            return "Invalid data received from iCloud."
        case .zoneCreationFailed:
            return "Failed to create family data zone in iCloud."
        case .shareCreationFailed:
            return "Failed to create family sharing in iCloud."
        case .invitationNotFound:
            return "Family invitation not found or has expired."
        case .memberNotFound:
            return "Family member not found."
        case .permissionDenied:
            return "You don't have permission to perform this action."
        case .networkError:
            return "Network connection error. Please try again."
        case .unknownError:
            return "An unknown error occurred. Please try again."
        }
    }
}