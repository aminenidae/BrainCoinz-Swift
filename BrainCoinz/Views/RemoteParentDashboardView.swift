//
//  RemoteParentDashboardView.swift
//  BrainCoinz
//
//  Remote parent dashboard for managing child devices from a separate parent device
//  Provides real-time monitoring and control of children's screen time across devices
//

import SwiftUI
import FamilyControls

/**
 * Remote parent dashboard that allows parents to manage their children's screen time
 * from their own device. This view provides comprehensive remote control capabilities
 * including real-time monitoring, goal management, and app blocking/unblocking.
 */
struct RemoteParentDashboardView: View {
    @EnvironmentObject var familyAccountManager: FamilyAccountManager
    @EnvironmentObject var sharedFamilyManager: SharedFamilyManager
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    @State private var selectedChildDevice: ConnectedDevice?
    @State private var showingFamilySetup = false
    @State private var showingDevicePairing = false
    @State private var showingRemoteGoalCreation = false
    @State private var familyCode = ""
    
    var body: some View {
        NavigationView {
            if sharedFamilyManager.currentFamily == nil {
                // Show family setup using the new SharedFamilyManager
                FamilySetupView()
            } else {
                // Main remote dashboard
                mainDashboardView
            }
        }
        .sheet(isPresented: $showingRemoteGoalCreation) {
            if let selectedDevice = selectedChildDevice {
                RemoteGoalCreationView(targetDevice: selectedDevice)
            }
        }
    }
    
    private var mainDashboardView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Family overview header
                familyOverviewSection
                
                // Connected devices section
                connectedDevicesSection
                
                // Quick actions section  
                quickActionsSection
                
                // Recent activity section
                recentActivitySection
            }
            .padding()
        }
        .navigationTitle("Family Control")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Refresh Data") {
                        sharedFamilyManager.refreshFamilyData { _, _ in }
                    }
                    
                    Button("Family Settings") {
                        showingFamilySetup = true
                    }
                    
                    Divider()
                    
                    Button("Sign Out", role: .destructive) {
                        authManager.signOut()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .refreshable {
            sharedFamilyManager.refreshFamilyData { _, _ in }
        }
    }
    
    private var familyOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    if let family = sharedFamilyManager.currentFamily {
                        Text(family.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Family ID: \(family.id.uuidString.prefix(8))...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    syncStatusIndicator
                    
                    if let lastSync = sharedFamilyManager.lastSyncDate {
                        Text("Last sync: \(lastSync, style: .relative)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var syncStatusIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(syncStatusColor)
                .frame(width: 8, height: 8)
            
            Text(syncStatusText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var syncStatusColor: Color {
        switch sharedFamilyManager.syncStatus {
        case .idle:
            return .gray
        case .syncing:
            return .orange
        case .success:
            return .green
        case .failed:
            return .red
        }
    }
    
    private var syncStatusText: String {
        switch sharedFamilyManager.syncStatus {
        case .idle:
            return "Ready"
        case .syncing:
            return "Syncing..."
        case .success:
            return "Synced"
        case .failed:
            return "Failed"
        }
    }
    
    private var connectedDevicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Connected Devices")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Add Device") {
                    showingDevicePairing = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // Show parent devices separately
            let parentMembers = sharedFamilyManager.familyMembers.filter { $0.role == .parent || $0.role == .organizer }
            if !parentMembers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Parent Devices (\(parentMembers.count))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(parentMembers) { member in
                            FamilyMemberCard(
                                member: member,
                                isSelected: false
                            ) {
                                // Parent devices don't need selection for remote commands
                            }
                        }
                    }
                }
            }
            
            // Show child devices
            let childMembers = sharedFamilyManager.familyMembers.filter { $0.role == .child }
            if !childMembers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Child Devices (\(childMembers.count))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(childMembers) { member in
                            FamilyMemberCard(
                                member: member,
                                isSelected: selectedChildDevice?.deviceID == member.deviceID
                            ) {
                                // Convert FamilyMember to ConnectedDevice for backward compatibility
                                selectedChildDevice = ConnectedDevice(
                                    deviceID: member.deviceID,
                                    deviceName: member.deviceName,
                                    userName: member.name,
                                    deviceType: "child",
                                    isActive: member.isOnline,
                                    lastSeen: member.lastSeen
                                )
                            }
                        }
                    }
                }
            }
            
            if sharedFamilyManager.familyMembers.isEmpty {
                EmptyDevicesView()
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            if !sharedFamilyManager.canManageFamily {
                VStack(spacing: 8) {
                    Image(systemName: "lock.shield")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    Text("Only parents and organizers can send remote commands")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            } else if let selectedDevice = selectedChildDevice {
                SelectedDeviceActionsView(device: selectedDevice)
            } else {
                Text("Select a child device to view available actions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Recent commands and activity log
            RecentActivityView()
        }
    }
}

/**
 * Family setup view for creating or joining a family account
 */
struct FamilySetupView: View {
    @EnvironmentObject var familyAccountManager: FamilyAccountManager
    @Binding var showingSetup: Bool
    @Binding var familyCode: String
    
    @State private var isCreatingFamily = true
    @State private var familyName = ""
    @State private var parentName = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "house.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Family Setup")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Set up remote family control to manage your children's devices")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Setup options
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    SetupOptionButton(
                        title: "Create Family",
                        icon: "plus.circle.fill",
                        isSelected: isCreatingFamily
                    ) {
                        isCreatingFamily = true
                    }
                    
                    SetupOptionButton(
                        title: "Join Family",
                        icon: "person.2.circle.fill",
                        isSelected: !isCreatingFamily
                    ) {
                        isCreatingFamily = false
                    }
                }
                
                // Setup form
                VStack(spacing: 16) {
                    if isCreatingFamily {
                        TextField("Family Name", text: $familyName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Your Name", text: $parentName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        TextField("Family Code", text: $familyCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Button(action: setupFamily) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            }
                            
                            Text(isCreatingFamily ? "Create Family" : "Join Family")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading || !isFormValid)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    /**
     * Presents options for joining as parent or child
     */
    private func presentJoinAsParentOption() {
        // For now, we'll default to parent joining
        // In a production app, you'd show an alert or sheet
        joinAsParent()
    }
    
    private func joinAsParent() {
        let parentName = "Parent \(Int.random(in: 1...99))"
        
        familyAccountManager.joinFamilyAsParent(
            familyCode: familyCode,
            parentName: parentName
        ) { success, error in
            self.isLoading = false
            if !success {
                self.errorMessage = error?.localizedDescription ?? "Failed to join as parent"
            }
        }
    }
    
    private func joinAsChild() {
        familyAccountManager.joinFamilyAccount(
            familyCode: familyCode,
            childName: "Child Device"
        ) { success, error in
            self.isLoading = false
            if !success {
                self.errorMessage = error?.localizedDescription ?? "Failed to join as child"
            }
        }
    }
    
    private var isFormValid: Bool {
        if isCreatingFamily {
            return !familyName.isEmpty && !parentName.isEmpty
        } else {
            return familyCode.count == 6
        }
    }
    
    private func setupFamily() {
        isLoading = true
        errorMessage = ""
        
        if isCreatingFamily {
            familyAccountManager.createFamilyAccount(
                familyName: familyName,
                parentName: parentName
            ) { success, error in
                isLoading = false
                if !success {
                    errorMessage = error?.localizedDescription ?? "Failed to create family"
                }
            }
        } else {
            // Join family implementation - with option to join as parent or child
            if isCreatingFamily {
                familyAccountManager.createFamilyAccount(
                    familyName: familyName,
                    parentName: parentName
                ) { success, error in
                    isLoading = false
                    if !success {
                        errorMessage = error?.localizedDescription ?? "Failed to create family"
                    }
                }
            } else {
                // Ask user if they want to join as parent or child
                presentJoinAsParentOption()
            }
        }
    }
}

/**
 * Setup option button for family creation/joining
 */
struct SetupOptionButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                
                Text(title)
                    .font(.headline)
            }
            .foregroundColor(isSelected ? .white : .blue)
            .frame(width: 140, height: 100)
            .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: isSelected ? 0 : 2)
            )
        }
    }
}

/**
 * Device card showing connected device info
 */
struct DeviceCard: View {
    let device: ConnectedDevice
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: deviceIcon)
                        .font(.title2)
                        .foregroundColor(deviceTypeColor)
                    
                    Spacer()
                    
                    Circle()
                        .fill(device.isActive ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                }
                
                Text(device.userName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(device.deviceName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Last seen: \(device.lastSeen, style: .relative)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
    
    private var deviceIcon: String {
        switch device.deviceType {
        case "parent":
            return "person.badge.shield.checkmark"
        case "child":
            return "iphone"
        default:
            return "questionmark.circle"
        }
    }
    
    private var deviceTypeColor: Color {
        switch device.deviceType {
        case "parent":
            return .blue
        case "child":
            return .green
        default:
            return .gray
        }
    }
}

/**
 * Family member card for the new SharedFamilyManager system
 */
struct FamilyMemberCard: View {
    let member: FamilyMember
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: memberIcon)
                        .font(.title2)
                        .foregroundColor(memberRoleColor)
                    
                    Spacer()
                    
                    Circle()
                        .fill(member.isOnline ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                }
                
                Text(member.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(member.deviceName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(member.role.displayName)
                        .font(.caption2)
                        .foregroundColor(memberRoleColor)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if member.isCurrentUser {
                        Text("You")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    }
                }
                
                Text("Last seen: \(member.lastSeen, style: .relative)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
    
    private var memberIcon: String {
        switch member.role {
        case .organizer:
            return "crown.fill"
        case .parent:
            return "person.badge.shield.checkmark"
        case .guardian:
            return "shield.fill"
        case .child:
            return "iphone"
        }
    }
    
    private var memberRoleColor: Color {
        switch member.role {
        case .organizer:
            return .orange
        case .parent:
            return .blue
        case .guardian:
            return .green
        case .child:
            return .purple
        }
    }
}

/**
 * Actions available for selected child device
 */
struct SelectedDeviceActionsView: View {
    @EnvironmentObject var familyAccountManager: FamilyAccountManager
    @EnvironmentObject var sharedFamilyManager: SharedFamilyManager
    let device: ConnectedDevice
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            ActionButton(
                title: "Block Apps",
                icon: "hand.raised.fill",
                color: .red
            ) {
                sendBlockAppsCommand()
            }
            
            ActionButton(
                title: "Unblock Apps", 
                icon: "hand.thumbsup.fill",
                color: .green
            ) {
                sendUnblockAppsCommand()
            }
            
            ActionButton(
                title: "Create Goal",
                icon: "target",
                color: .blue
            ) {
                // Navigate to goal creation
            }
            
            ActionButton(
                title: "Send Message",
                icon: "message.fill",
                color: .orange
            ) {
                sendMessageCommand()
            }
        }
    }
    
    private func sendBlockAppsCommand() {
        guard sharedFamilyManager.canManageFamily else {
            // Show error - only parents/organizers can send commands
            return
        }
        
        let command = RemoteControlCommand(
            type: .blockApps,
            data: ["action": "block_all_reward_apps"],
            timestamp: Date()
        )
        
        sharedFamilyManager.sendCrossFamilyCommand(command, to: device.deviceID) { success in
            // Handle result
        }
    }
    
    private func sendUnblockAppsCommand() {
        guard sharedFamilyManager.canManageFamily else {
            // Show error - only parents/organizers can send commands
            return
        }
        
        let command = RemoteControlCommand(
            type: .unblockApps,
            data: ["action": "unblock_all_reward_apps"],
            timestamp: Date()
        )
        
        sharedFamilyManager.sendCrossFamilyCommand(command, to: device.deviceID) { success in
            // Handle result
        }
    }
    
    private func sendMessageCommand() {
        guard sharedFamilyManager.canManageFamily else {
            // Show error - only parents/organizers can send commands
            return
        }
        
        let command = RemoteControlCommand(
            type: .sendMessage,
            data: ["message": "Great job on your learning time today!"],
            timestamp: Date()
        )
        
        sharedFamilyManager.sendCrossFamilyCommand(command, to: device.deviceID) { success in
            // Handle result
        }
    }
}

/**
 * Action button for remote commands
 */
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(color)
            .cornerRadius(12)
        }
    }
}

/**
 * Empty state for when no devices are connected
 */
struct EmptyDevicesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "iphone.slash")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No Connected Devices")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Add child devices to start managing screen time remotely")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

/**
 * Recent activity log view
 */
struct RecentActivityView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Sample activity items
            ActivityLogItem(
                icon: "hand.raised.fill",
                action: "Blocked reward apps",
                device: "Emma's iPhone",
                timestamp: Date().addingTimeInterval(-300)
            )
            
            ActivityLogItem(
                icon: "target",
                action: "Goal completed",
                device: "Emma's iPhone", 
                timestamp: Date().addingTimeInterval(-1800)
            )
            
            ActivityLogItem(
                icon: "message.fill",
                action: "Message sent",
                device: "Emma's iPhone",
                timestamp: Date().addingTimeInterval(-3600)
            )
        }
    }
}

/**
 * Activity log item
 */
struct ActivityLogItem: View {
    let icon: String
    let action: String
    let device: String
    let timestamp: Date
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(action)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(device)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(timestamp, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RemoteParentDashboardView()
        .environmentObject(FamilyAccountManager())
        .environmentObject(SharedFamilyManager())
        .environmentObject(AuthenticationManager())
        .environmentObject(NotificationManager())
}