//
//  GoalCreationView.swift
//  BrainCoinz
//
//  View for creating new learning goals with app selection and time targets
//

import SwiftUI
import FamilyControls
import CoreData

/**
 * View for creating new learning goals including:
 * - Setting daily time targets
 * - Selecting learning apps
 * - Selecting reward apps
 * - Configuring goal parameters
 */
struct GoalCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var familyControlsManager: FamilyControlsManager
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var targetMinutes = 30
    @State private var goalName = ""
    @State private var showingLearningAppPicker = false
    @State private var showingRewardAppPicker = false
    @State private var isCreating = false
    
    var body: some View {
        NavigationView {
            Form {
                // Goal Information Section
                Section("Goal Information") {
                    TextField("Goal Name (Optional)", text: $goalName)
                    
                    HStack {
                        Text("Daily Target")
                        Spacer()
                        Picker("Minutes", selection: $targetMinutes) {
                            ForEach([15, 30, 45, 60, 90, 120], id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                // Learning Apps Section
                Section("Learning Apps") {
                    Button(action: { showingLearningAppPicker = true }) {
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading) {
                                Text("Select Learning Apps")
                                    .foregroundColor(.primary)
                                
                                if familyControlsManager.hasLearningApps() {
                                    Text("\(familyControlsManager.selectedLearningApps.applications.count) apps selected")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("No apps selected")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if familyControlsManager.hasLearningApps() {
                        ForEach(familyControlsManager.getLearningAppNames(), id: \.self) { appName in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text(appName)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // Reward Apps Section
                Section("Reward Apps") {
                    Button(action: { showingRewardAppPicker = true }) {
                        HStack {
                            Image(systemName: "gift.fill")
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading) {
                                Text("Select Reward Apps")
                                    .foregroundColor(.primary)
                                
                                if familyControlsManager.hasRewardApps() {
                                    Text("\(familyControlsManager.selectedRewardApps.applications.count) apps selected")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("No apps selected")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if familyControlsManager.hasRewardApps() {
                        ForEach(familyControlsManager.getRewardAppNames(), id: \.self) { appName in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text(appName)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // Goal Summary
                Section("Goal Summary") {
                    HStack {
                        Text("Target Time")
                        Spacer()
                        Text("\(targetMinutes) minutes daily")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Learning Apps")
                        Spacer()
                        Text("\(familyControlsManager.selectedLearningApps.applications.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Reward Apps")
                        Spacer()
                        Text("\(familyControlsManager.selectedRewardApps.applications.count)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Create Goal")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createGoal()
                    }
                    .disabled(!canCreateGoal || isCreating)
                }
            }
        }
        .sheet(isPresented: $showingLearningAppPicker) {
            FamilyActivityPickerView(
                selection: $familyControlsManager.selectedLearningApps,
                isPresented: $showingLearningAppPicker,
                pickerType: .learning
            )
        }
        .sheet(isPresented: $showingRewardAppPicker) {
            FamilyActivityPickerView(
                selection: $familyControlsManager.selectedRewardApps,
                isPresented: $showingRewardAppPicker,
                pickerType: .reward
            )
        }
    }
    
    private var canCreateGoal: Bool {
        return familyControlsManager.hasLearningApps() && familyControlsManager.hasRewardApps()
    }
    
    private func createGoal() {
        guard let currentUser = authManager.currentUser else { return }
        
        isCreating = true
        
        // Create the learning goal
        let newGoal = LearningGoal(context: viewContext)
        newGoal.goalID = UUID()
        newGoal.targetDurationMinutes = Int32(targetMinutes)
        newGoal.isActive = true
        newGoal.createdAt = Date()
        newGoal.updatedAt = Date()
        newGoal.user = currentUser
        
        // Create selected app entities
        familyControlsManager.createLearningAppEntities(for: newGoal, context: viewContext)
        familyControlsManager.createRewardAppEntities(for: newGoal, context: viewContext)
        
        do {
            try viewContext.save()
            
            // Clear selections for next goal
            familyControlsManager.clearLearningApps()
            familyControlsManager.clearRewardApps()
            
            dismiss()
        } catch {
            print("Failed to create goal: \(error)")
            isCreating = false
        }
    }
}

struct GoalRowView: View {
    let goal: LearningGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(goal.targetDurationMinutes) minutes daily")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Created \(goal.createdAt, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if goal.isActive {
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            HStack {
                Label("\(goal.learningApps?.count ?? 0) learning apps", systemImage: "book.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Spacer()
                
                Label("\(goal.rewardApps?.count ?? 0) reward apps", systemImage: "gift.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ParentSettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var familyControlsManager: FamilyControlsManager
    @EnvironmentObject var managedSettingsManager: ManagedSettingsManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    HStack {
                        Text("Signed in as")
                        Spacer()
                        Text("Parent")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Sign Out") {
                        authManager.signOut()
                    }
                    .foregroundColor(.red)
                }
                
                Section("Family Controls") {
                    HStack {
                        Text("Authorization Status")
                        Spacer()
                        Text(familyControlsManager.authorizationStatus.displayName)
                            .foregroundColor(familyControlsManager.isAuthorized ? .green : .red)
                    }
                    
                    if !familyControlsManager.isAuthorized {
                        Button("Request Authorization") {
                            Task {
                                await familyControlsManager.requestAuthorization()
                            }
                        }
                    }
                }
                
                Section("Notifications") {
                    HStack {
                        Text("Permission Status")
                        Spacer()
                        Text(notificationManager.notificationPermissionGranted ? "Granted" : "Not Granted")
                            .foregroundColor(notificationManager.notificationPermissionGranted ? .green : .red)
                    }
                    
                    if !notificationManager.notificationPermissionGranted {
                        Button("Request Permission") {
                            notificationManager.requestPermissions()
                        }
                    }
                }
                
                Section("Data Management") {
                    Button("Clear All Settings") {
                        managedSettingsManager.clearAllSettings()
                    }
                    .foregroundColor(.orange)
                    
                    Button("Reset App Data") {
                        authManager.resetAuthenticationData()
                    }
                    .foregroundColor(.red)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://braincoinz.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://braincoinz.com/terms")!)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct ProgressBar: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * progress, height: 8)
                    .cornerRadius(4)
                    .animation(.easeInOut(duration: 0.5), value: progress)
            }
        }
        .frame(height: 8)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct UsageSessionRow: View {
    let session: AppUsageSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(session.duration / 60)) minutes")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(session.startTime, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "clock")
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    GoalCreationView()
        .environmentObject(FamilyControlsManager())
        .environmentObject(AuthenticationManager())
}