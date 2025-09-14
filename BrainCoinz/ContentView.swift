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
    
    var body: some View {
        Group {
            if !authManager.hasCompletedOnboarding {
                // Show onboarding flow for first-time users
                OnboardingView()
            } else if authManager.isAuthenticated {
                // Show appropriate dashboard based on user role
                if authManager.currentUserRole == .parent {
                    ParentDashboardView()
                } else {
                    ChildDashboardView()
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
}