//
//  BrainCoinzApp.swift
//  BrainCoinz
//
//  Created on 2025-01-14
//  iOS Parental Control Screen Time App with Reward Function
//

import SwiftUI
import FamilyControls
import ManagedSettings
import DeviceActivity

/**
 * Main app entry point for BrainCoinz - A parental control app that uses screen time
 * to motivate children by unlocking reward apps after learning goals are achieved.
 * 
 * This app integrates with Apple's Screen Time APIs including:
 * - FamilyControls: For parental authorization and app selection
 * - ManagedSettings: For blocking/unblocking apps
 * - DeviceActivity: For monitoring screen time usage
 */
@main
struct BrainCoinzApp: App {
    
    // Shared managers for the entire app lifecycle
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var familyControlsManager = FamilyControlsManager()
    @StateObject private var deviceActivityManager = DeviceActivityManager()
    @StateObject private var managedSettingsManager = ManagedSettingsManager()
    @StateObject private var notificationManager = NotificationManager()
    
    // Core Data persistence container
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(familyControlsManager)
                .environmentObject(deviceActivityManager)
                .environmentObject(managedSettingsManager)
                .environmentObject(notificationManager)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    /**
     * Initializes the app by setting up notifications and checking authorization status
     */
    private func setupApp() {
        // Request notification permissions
        notificationManager.requestPermissions()
        
        // Check if Family Controls is already authorized
        if familyControlsManager.isAuthorized {
            // Initialize managers that depend on Family Controls authorization
            deviceActivityManager.initialize()
            managedSettingsManager.initialize()
        }
    }
}

/**
 * Core Data persistence controller for managing local data storage
 * Handles user profiles, app selections, goals, and usage data
 */
class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DataModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // In production, handle this error appropriately
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // Enable automatic merging of changes from parent context
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    /**
     * Saves the current context to persist changes to Core Data
     */
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}