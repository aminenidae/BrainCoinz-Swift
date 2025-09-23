//
//  ContentView.swift
//  BrainCoinz
//
//  Main navigation view that determines which screen to show based on user authentication
//  and onboarding status
//

import SwiftUI

/**
 * Main content view that handles navigation between different app states:
 * - Onboarding flow for new users
 * - Parent dashboard for authenticated parents
 * - Child dashboard for authenticated children
 */
struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var familyControlsManager: FamilyControlsManager
    @EnvironmentObject var familyAccountManager: FamilyAccountManager
    @EnvironmentObject var sharedFamilyManager: SharedFamilyManager
    
    @State private var showingParentModeSelection = false
    
    var body: some View {
        Group {
            if !authManager.hasCompletedOnboarding {
                // Show onboarding flow for first-time users
                OnboardingView()
            } else if authManager.isAuthenticated {
                // Show appropriate dashboard based on user role
                if authManager.currentUserRole == .parent {
                    ParentModeSelectionView()
                } else {
                    CoinzChildDashboardView()
                }
            } else {
                // Show authentication screen
                AuthenticationView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: authManager.hasCompletedOnboarding)
    }
}

/**
 * Authentication view for user login/registration
 */
struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isParentMode = true
    @State private var parentCode = ""
    @State private var childName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Logo and Title
                VStack(spacing: 16) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("BrainCoinz")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Smart Screen Time Management")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // User Role Selection
                VStack(spacing: 20) {
                    Text("Who are you?")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 20) {
                        RoleSelectionButton(
                            title: "Parent",
                            icon: "person.badge.shield.checkmark",
                            isSelected: isParentMode
                        ) {
                            isParentMode = true
                        }
                        
                        RoleSelectionButton(
                            title: "Child",
                            icon: "person.crop.circle",
                            isSelected: !isParentMode
                        ) {
                            isParentMode = false
                        }
                    }
                }
                
                // Authentication Form
                VStack(spacing: 16) {
                    if isParentMode {
                        SecureField("Parent Access Code", text: $parentCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    } else {
                        TextField("Child Name", text: $childName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    Button(action: authenticate) {
                        Text(isParentMode ? "Sign In as Parent" : "Sign In as Child")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled((isParentMode && parentCode.isEmpty) || (!isParentMode && childName.isEmpty))
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
        .alert("Authentication Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    /**
     * Handles authentication based on selected user role
     */
    private func authenticate() {
        if isParentMode {
            authManager.authenticateParent(with: parentCode) { success, error in
                if !success {
                    alertMessage = error ?? "Invalid parent code"
                    showingAlert = true
                }
            }
        } else {
            authManager.authenticateChild(name: childName) { success, error in
                if !success {
                    alertMessage = error ?? "Authentication failed"
                    showingAlert = true
                }
            }
        }
    }
}

/**
 * Reusable button component for role selection
 */
struct RoleSelectionButton: View {
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
            .frame(width: 120, height: 100)
            .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: isSelected ? 0 : 2)
            )
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
        .environmentObject(FamilyControlsManager())
        .environmentObject(FamilyAccountManager())
        .environmentObject(SharedFamilyManager())
        .environmentObject(CoinzManager())
}

/**
 * Parent mode selection view to choose between local control and remote control
 */
struct ParentModeSelectionView: View {
    @EnvironmentObject var familyAccountManager: FamilyAccountManager
    @EnvironmentObject var sharedFamilyManager: SharedFamilyManager
    @State private var selectedMode: ParentMode = .local
    
    enum ParentMode {
        case local
        case remote
        case familyManagement
        case coinzConfig
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Image(systemName: "person.badge.shield.checkmark")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Parent Control Mode")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Choose how you want to manage screen time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                Spacer()
                
                VStack(spacing: 20) {
                    VStack(spacing: 15) {
                        HStack(spacing: 15) {
                            ParentModeButton(
                                mode: .local,
                                title: "This Device",
                                subtitle: "Control this device directly",
                                icon: "iphone",
                                isSelected: selectedMode == .local
                            ) {
                                selectedMode = .local
                            }
                            
                            ParentModeButton(
                                mode: .remote,
                                title: "Remote Control",
                                subtitle: "Manage family devices remotely",
                                icon: "externaldrive.connected.to.line.below",
                                isSelected: selectedMode == .remote
                            ) {
                                selectedMode = .remote
                            }
                        }
                        
                        HStack(spacing: 15) {
                            ParentModeButton(
                                mode: .familyManagement,
                                title: "Family Management",
                                subtitle: "Manage family members and settings",
                                icon: "person.3.sequence.fill",
                                isSelected: selectedMode == .familyManagement
                            ) {
                                selectedMode = .familyManagement
                            }
                            
                            ParentModeButton(
                                mode: .coinzConfig,
                                title: "Coinz System",
                                subtitle: "Configure learning rewards",
                                icon: "dollarsign.circle.fill",
                                isSelected: selectedMode == .coinzConfig
                            ) {
                                selectedMode = .coinzConfig
                            }
                        }
                    }
                    
                    Button("Continue") {
                        // Navigation handled by fullScreenCover
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: .constant(selectedMode == .local)) {
            if selectedMode == .local {
                ParentDashboardView()
            }
        }
        .fullScreenCover(isPresented: .constant(selectedMode == .remote)) {
            if selectedMode == .remote {
                RemoteParentDashboardView()
            }
        }
        .fullScreenCover(isPresented: .constant(selectedMode == .familyManagement)) {
            if selectedMode == .familyManagement {
                if sharedFamilyManager.currentFamily != nil {
                    FamilyManagementView()
                } else {
                    FamilySetupView()
                }
            }
        }
        .fullScreenCover(isPresented: .constant(selectedMode == .coinzConfig)) {
            if selectedMode == .coinzConfig {
                CoinzParentConfigView()
            }
        }
    }
}

/**
 * Parent mode selection button
 */
struct ParentModeButton: View {
    let mode: ParentModeSelectionView.ParentMode
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(isSelected ? .white : .blue)
            .frame(width: 140, height: 120)
            .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: isSelected ? 0 : 2)
            )
        }
    }
}