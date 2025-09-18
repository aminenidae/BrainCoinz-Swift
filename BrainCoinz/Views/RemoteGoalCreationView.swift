//
//  RemoteGoalCreationView.swift
//  BrainCoinz
//
//  Remote goal creation interface for parents to set learning goals on child devices
//  Allows parents to create and manage goals from their own device
//

import SwiftUI
import FamilyControls

/**
 * Remote goal creation view that allows parents to create learning goals
 * for their children's devices from their own parent device.
 */
struct RemoteGoalCreationView: View {
    @EnvironmentObject var familyAccountManager: FamilyAccountManager
    @Environment(\.dismiss) private var dismiss
    
    let targetDevice: ConnectedDevice
    
    @State private var goalName = ""
    @State private var targetDurationMinutes: Double = 30
    @State private var selectedLearningApps: FamilyActivitySelection = FamilyActivitySelection()
    @State private var selectedRewardApps: FamilyActivitySelection = FamilyActivitySelection()
    @State private var showingLearningAppPicker = false
    @State private var showingRewardAppPicker = false
    @State private var isCreating = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                // Target device section
                Section("Target Device") {
                    HStack {
                        Image(systemName: "iphone")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(targetDevice.userName)
                                .font(.headline)
                            
                            Text(targetDevice.deviceName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Circle()
                            .fill(targetDevice.isActive ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                    }
                }
                
                // Goal configuration section
                Section("Goal Configuration") {
                    TextField("Goal Name", text: $goalName)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Target Duration")
                            Spacer()
                            Text("\(Int(targetDurationMinutes)) minutes")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $targetDurationMinutes, in: 15...120, step: 15)
                            .accentColor(.blue)
                    }
                }
                
                // Learning apps section
                Section("Learning Apps") {
                    Button(action: { showingLearningAppPicker = true }) {
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundColor(.green)
                            
                            if selectedLearningApps.applications.isEmpty {
                                Text("Select Learning Apps")
                                    .foregroundColor(.blue)
                            } else {
                                Text("\(selectedLearningApps.applications.count) apps selected")
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !selectedLearningApps.applications.isEmpty {
                        ForEach(Array(selectedLearningApps.applications.prefix(3)), id: \.bundleIdentifier) { app in
                            HStack {
                                Image(systemName: "app.fill")
                                    .foregroundColor(.green)
                                
                                Text(app.localizedDisplayName ?? "Unknown App")
                                    .font(.caption)
                            }
                        }
                        
                        if selectedLearningApps.applications.count > 3 {
                            Text("and \(selectedLearningApps.applications.count - 3) more...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Reward apps section  
                Section("Reward Apps") {
                    Button(action: { showingRewardAppPicker = true }) {
                        HStack {
                            Image(systemName: "gamecontroller.fill")
                                .foregroundColor(.orange)
                            
                            if selectedRewardApps.applications.isEmpty {
                                Text("Select Reward Apps")
                                    .foregroundColor(.blue)
                            } else {
                                Text("\(selectedRewardApps.applications.count) apps selected")
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !selectedRewardApps.applications.isEmpty {
                        ForEach(Array(selectedRewardApps.applications.prefix(3)), id: \.bundleIdentifier) { app in
                            HStack {
                                Image(systemName: "app.fill")
                                    .foregroundColor(.orange)
                                
                                Text(app.localizedDisplayName ?? "Unknown App")
                                    .font(.caption)
                            }
                        }
                        
                        if selectedRewardApps.applications.count > 3 {
                            Text("and \(selectedRewardApps.applications.count - 3) more...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Goal description section
                Section("Description") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This goal will require \(targetDevice.userName) to use learning apps for \(Int(targetDurationMinutes)) minutes each day.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Once completed, reward apps will be automatically unlocked for the rest of the day.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Create Remote Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: createRemoteGoal) {
                        if isCreating {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Create")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isCreating || !isFormValid)
                }
            }
        }
        .sheet(isPresented: $showingLearningAppPicker) {
            FamilyActivityPickerView(
                selection: $selectedLearningApps,
                isPresented: $showingLearningAppPicker,
                pickerType: .learning
            )
        }
        .sheet(isPresented: $showingRewardAppPicker) {
            FamilyActivityPickerView(
                selection: $selectedRewardApps,
                isPresented: $showingRewardAppPicker,
                pickerType: .reward
            )
        }
    }
    
    private var isFormValid: Bool {
        return !goalName.isEmpty && 
               !selectedLearningApps.applications.isEmpty && 
               !selectedRewardApps.applications.isEmpty
    }
    
    /**
     * Creates a remote goal and sends it to the target device
     */
    private func createRemoteGoal() {
        isCreating = true
        errorMessage = ""
        
        // Create goal data structure
        let goalData: [String: Any] = [
            "goalName": goalName,
            "targetDurationMinutes": Int(targetDurationMinutes),
            "learningApps": selectedLearningApps.applications.map { app in
                [
                    "bundleIdentifier": app.bundleIdentifier,
                    "displayName": app.localizedDisplayName ?? "Unknown App"
                ]
            },
            "rewardApps": selectedRewardApps.applications.map { app in
                [
                    "bundleIdentifier": app.bundleIdentifier,
                    "displayName": app.localizedDisplayName ?? "Unknown App"
                ]
            },
            "createdAt": Date().timeIntervalSince1970
        ]
        
        // Convert to JSON string for command data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: goalData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            errorMessage = "Failed to create goal data"
            isCreating = false
            return
        }
        
        // Create remote command
        let command = RemoteControlCommand(
            type: .updateGoal,
            data: [
                "action": "create_goal",
                "goalData": jsonString
            ],
            timestamp: Date()
        )
        
        // Send command to target device
        familyAccountManager.sendRemoteCommand(command, to: targetDevice.deviceID) { success in
            DispatchQueue.main.async {
                isCreating = false
                
                if success {
                    dismiss()
                } else {
                    errorMessage = "Failed to send goal to device. Please try again."
                }
            }
        }
    }
}

/**
 * Preview provider for RemoteGoalCreationView
 */
#Preview {
    let sampleDevice = ConnectedDevice(
        deviceID: "sample-device-id",
        deviceType: "child",
        deviceName: "Emma's iPhone",
        userName: "Emma",
        registeredAt: Date(),
        lastSeen: Date(),
        isActive: true
    )
    
    return RemoteGoalCreationView(targetDevice: sampleDevice)
        .environmentObject(FamilyAccountManager())
}

/**
 * Extension to create a ConnectedDevice for preview purposes
 */
extension ConnectedDevice {
    init(deviceID: String, deviceType: String, deviceName: String, userName: String, registeredAt: Date, lastSeen: Date, isActive: Bool) {
        self.deviceID = deviceID
        self.deviceType = deviceType
        self.deviceName = deviceName
        self.userName = userName
        self.registeredAt = registeredAt
        self.lastSeen = lastSeen
        self.isActive = isActive
    }
}