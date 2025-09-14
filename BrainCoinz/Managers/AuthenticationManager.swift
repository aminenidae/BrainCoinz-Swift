//
//  AuthenticationManager.swift
//  BrainCoinz
//
//  Manages user authentication, role-based access, and user session state
//  Supports both parent and child authentication modes
//

import Foundation
import SwiftUI
import CoreData
import LocalAuthentication

/**
 * User roles within the BrainCoinz app
 */
enum UserRole: String, CaseIterable {
    case parent = "parent"
    case child = "child"
}

/**
 * Authentication manager responsible for user login, session management,
 * and role-based access control. Integrates with Core Data for user persistence
 * and Keychain for secure credential storage.
 */
class AuthenticationManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var currentUserRole: UserRole = .child
    @Published var currentUser: User?
    @Published var hasCompletedOnboarding = false
    
    // MARK: - Private Properties
    private let keychainService = "com.yourcompany.braincoinz"
    private let onboardingKey = "hasCompletedOnboarding"
    private let currentUserKey = "currentUserID"
    
    // Core Data context
    private var viewContext: NSManagedObjectContext {
        return PersistenceController.shared.container.viewContext
    }
    
    // MARK: - Initialization
    init() {
        loadAuthenticationState()
    }
    
    // MARK: - Public Methods
    
    /**
     * Authenticates a parent user with their access code
     * @param parentCode: The 4-6 digit parent access code
     * @param completion: Callback with success status and optional error message
     */
    func authenticateParent(with parentCode: String, completion: @escaping (Bool, String?) -> Void) {
        // Validate parent code format
        guard isValidParentCode(parentCode) else {
            completion(false, "Parent code must be 4-6 digits")
            return
        }
        
        // First check if parent exists, if not create one
        let parentUser = getOrCreateParentUser(with: parentCode)
        
        // Verify the parent code matches
        if parentUser.parentCode == parentCode {
            authenticateUser(parentUser, role: .parent)
            completion(true, nil)
        } else {
            completion(false, "Invalid parent access code")
        }
    }
    
    /**
     * Authenticates a child user with their name
     * @param name: The child's name for identification
     * @param completion: Callback with success status and optional error message
     */
    func authenticateChild(name: String, completion: @escaping (Bool, String?) -> Void) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(false, "Child name cannot be empty")
            return
        }
        
        // Get or create child user
        let childUser = getOrCreateChildUser(with: name)
        authenticateUser(childUser, role: .child)
        completion(true, nil)
    }
    
    /**
     * Signs out the current user and clears authentication state
     */
    func signOut() {
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.currentUser = nil
            self.currentUserRole = .child
        }
        
        // Remove current user from UserDefaults
        UserDefaults.standard.removeObject(forKey: currentUserKey)
    }
    
    /**
     * Marks onboarding as completed
     */
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }
    
    /**
     * Resets all authentication data (for testing/debugging)
     */
    func resetAuthenticationData() {
        signOut()
        UserDefaults.standard.removeObject(forKey: onboardingKey)
        hasCompletedOnboarding = false
        
        // Clear all users from Core Data
        clearAllUsers()
    }
    
    /**
     * Creates a new parent access code
     * @return: A randomly generated 4-digit parent code
     */
    func generateParentCode() -> String {
        return String(format: "%04d", Int.random(in: 1000...9999))
    }
    
    /**
     * Validates if current user has parent privileges
     */
    func requiresParentAuthentication(completion: @escaping (Bool) -> Void) {
        if currentUserRole == .parent {
            completion(true)
            return
        }
        
        // Request biometric or parent code authentication
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication,
                                 localizedReason: "Authenticate to access parental controls") { success, _ in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        } else {
            completion(false)
        }
    }
    
    // MARK: - Private Methods
    
    /**
     * Loads authentication state from persistent storage
     */
    private func loadAuthenticationState() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        
        // Try to restore previous user session
        if let userIDString = UserDefaults.standard.string(forKey: currentUserKey),
           let userID = UUID(uuidString: userIDString) {
            restoreUserSession(userID: userID)
        }
    }
    
    /**
     * Restores user session from stored user ID
     */
    private func restoreUserSession(userID: UUID) {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", userID as CVarArg)
        
        do {
            let users = try viewContext.fetch(request)
            if let user = users.first {
                authenticateUser(user, role: UserRole(rawValue: user.role) ?? .child)
            }
        } catch {
            print("Failed to restore user session: \(error)")
        }
    }
    
    /**
     * Authenticates a user and updates the app state
     */
    private func authenticateUser(_ user: User, role: UserRole) {
        DispatchQueue.main.async {
            self.currentUser = user
            self.currentUserRole = role
            self.isAuthenticated = true
        }
        
        // Store current user ID for session restoration
        UserDefaults.standard.set(user.userID.uuidString, forKey: currentUserKey)
    }
    
    /**
     * Gets existing parent user or creates a new one
     */
    private func getOrCreateParentUser(with parentCode: String) -> User {
        // First try to find existing parent
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "role == %@ AND parentCode == %@", 
                                      UserRole.parent.rawValue, parentCode)
        
        do {
            let existingParents = try viewContext.fetch(request)
            if let existingParent = existingParents.first {
                return existingParent
            }
        } catch {
            print("Error fetching parent user: \(error)")
        }
        
        // Create new parent user
        let newParent = User(context: viewContext)
        newParent.userID = UUID()
        newParent.name = "Parent"
        newParent.role = UserRole.parent.rawValue
        newParent.parentCode = parentCode
        newParent.createdAt = Date()
        newParent.isActive = true
        
        saveContext()
        return newParent
    }
    
    /**
     * Gets existing child user or creates a new one
     */
    private func getOrCreateChildUser(with name: String) -> User {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to find existing child with the same name
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "role == %@ AND name == %@", 
                                      UserRole.child.rawValue, trimmedName)
        
        do {
            let existingChildren = try viewContext.fetch(request)
            if let existingChild = existingChildren.first {
                return existingChild
            }
        } catch {
            print("Error fetching child user: \(error)")
        }
        
        // Create new child user
        let newChild = User(context: viewContext)
        newChild.userID = UUID()
        newChild.name = trimmedName
        newChild.role = UserRole.child.rawValue
        newChild.createdAt = Date()
        newChild.isActive = true
        
        saveContext()
        return newChild
    }
    
    /**
     * Validates parent code format
     */
    private func isValidParentCode(_ code: String) -> Bool {
        return code.count >= 4 && code.count <= 6 && code.allSatisfy { $0.isNumber }
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
    
    /**
     * Clears all users from Core Data (for reset functionality)
     */
    private func clearAllUsers() {
        let request: NSFetchRequest<NSFetchRequestResult> = User.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try viewContext.execute(deleteRequest)
            try viewContext.save()
        } catch {
            print("Failed to clear users: \(error)")
        }
    }
}

// MARK: - User Entity Extensions

extension User {
    
    /**
     * Computed property to get user role as enum
     */
    var userRole: UserRole {
        return UserRole(rawValue: role) ?? .child
    }
    
    /**
     * Computed property to check if user is a parent
     */
    var isParent: Bool {
        return userRole == .parent
    }
    
    /**
     * Computed property to check if user is a child
     */
    var isChild: Bool {
        return userRole == .child
    }
}