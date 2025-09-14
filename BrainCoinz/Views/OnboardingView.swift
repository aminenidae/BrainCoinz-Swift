//
//  OnboardingView.swift
//  BrainCoinz
//
//  Onboarding flow for new users including permission requests and app introduction
//  Guides users through Family Controls setup and explains app functionality
//

import SwiftUI
import FamilyControls

/**
 * Comprehensive onboarding view that introduces new users to BrainCoinz
 * and guides them through the necessary permission setups including
 * Family Controls authorization and notification permissions.
 */
struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var familyControlsManager: FamilyControlsManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    @State private var currentPage = 0
    @State private var showingFamilyControlsAuth = false
    
    private let totalPages = 5
    
    var body: some View {
        VStack {
            // Progress Indicator
            ProgressIndicator(currentPage: currentPage, totalPages: totalPages)
                .padding(.top)
            
            // Page Content
            TabView(selection: $currentPage) {
                WelcomePage()
                    .tag(0)
                
                FeaturePage()
                    .tag(1)
                
                FamilyControlsPermissionPage()
                    .tag(2)
                
                NotificationPermissionPage()
                    .tag(3)
                
                CompletionPage()
                    .tag(4)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            // Navigation Buttons
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                if currentPage < totalPages - 1 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                } else {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }
    
    private func completeOnboarding() {
        authManager.completeOnboarding()
    }
}

/**
 * Welcome page introducing the app
 */
struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App Icon and Title
            VStack(spacing: 20) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 100))
                    .foregroundColor(.blue)
                
                Text("Welcome to BrainCoinz")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Smart Screen Time Management for Families")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Key Benefits
            VStack(alignment: .leading, spacing: 16) {
                BenefitRow(
                    icon: "target",
                    title: "Set Learning Goals",
                    description: "Encourage educational app usage"
                )
                
                BenefitRow(
                    icon: "gift.fill",
                    title: "Unlock Rewards",
                    description: "Earn access to fun apps after learning"
                )
                
                BenefitRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Track Progress",
                    description: "Monitor learning time and achievements"
                )
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

/**
 * Feature explanation page
 */
struct FeaturePage: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("How It Works")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            ScrollView {
                VStack(spacing: 24) {
                    FeatureCard(
                        step: "1",
                        title: "Choose Learning Apps",
                        description: "Select educational apps like Khan Academy, Duolingo, or reading apps that promote learning.",
                        icon: "book.fill",
                        color: .green
                    )
                    
                    FeatureCard(
                        step: "2",
                        title: "Set Time Goals",
                        description: "Decide how many minutes of learning time are needed each day to unlock rewards.",
                        icon: "clock.fill",
                        color: .blue
                    )
                    
                    FeatureCard(
                        step: "3",
                        title: "Select Reward Apps",
                        description: "Choose fun apps like games or social media that will be unlocked after goals are met.",
                        icon: "gamecontroller.fill",
                        color: .orange
                    )
                    
                    FeatureCard(
                        step: "4",
                        title: "Learn & Earn",
                        description: "Use learning apps to reach daily goals and automatically unlock access to reward apps!",
                        icon: "star.fill",
                        color: .yellow
                    )
                }
            }
        }
        .padding()
    }
}

/**
 * Family Controls permission request page
 */
struct FamilyControlsPermissionPage: View {
    @EnvironmentObject var familyControlsManager: FamilyControlsManager
    
    @State private var isRequesting = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Family Controls Permission")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            VStack(spacing: 20) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Screen Time Management")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("BrainCoinz needs permission to manage screen time and app access. This allows us to:")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                PermissionItem(
                    icon: "apps.iphone",
                    text: "Monitor app usage for learning tracking"
                )
                
                PermissionItem(
                    icon: "lock.shield",
                    text: "Block reward apps until goals are met"
                )
                
                PermissionItem(
                    icon: "chart.bar.fill",
                    text: "Provide usage statistics and progress"
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Spacer()
            
            VStack(spacing: 16) {
                if familyControlsManager.isAuthorized {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Family Controls Authorized")
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }
                } else {
                    Button(action: requestFamilyControlsAuth) {
                        HStack {
                            if isRequesting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isRequesting ? "Requesting..." : "Grant Permission")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .disabled(isRequesting)
                    
                    Text("This permission is required for the app to work properly")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
    }
    
    private func requestFamilyControlsAuth() {
        isRequesting = true
        
        Task {
            await familyControlsManager.requestAuthorization()
            await MainActor.run {
                isRequesting = false
            }
        }
    }
}

/**
 * Notification permission request page
 */
struct NotificationPermissionPage: View {
    @EnvironmentObject var notificationManager: NotificationManager
    
    @State private var isRequesting = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Stay Informed")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            VStack(spacing: 20) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                Text("Notifications")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Get notified about learning progress, goal completions, and reward unlocks.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                NotificationItem(
                    icon: "target",
                    text: "Goal completion celebrations"
                )
                
                NotificationItem(
                    icon: "chart.line.uptrend.xyaxis",
                    text: "Learning progress updates"
                )
                
                NotificationItem(
                    icon: "clock",
                    text: "Daily learning reminders"
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Spacer()
            
            VStack(spacing: 16) {
                if notificationManager.notificationPermissionGranted {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Notifications Enabled")
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }
                } else {
                    Button(action: requestNotificationPermission) {
                        HStack {
                            if isRequesting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isRequesting ? "Requesting..." : "Enable Notifications")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                    }
                    .disabled(isRequesting)
                    
                    Text("You can change this later in Settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
    }
    
    private func requestNotificationPermission() {
        isRequesting = true
        notificationManager.requestPermissions()
        
        // Simulate delay for UI feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isRequesting = false
        }
    }
}

/**
 * Onboarding completion page
 */
struct CompletionPage: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.green)
                
                Text("All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("You're ready to start using BrainCoinz")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                NextStepItem(
                    step: "1",
                    text: "Sign in as a parent to set up learning goals"
                )
                
                NextStepItem(
                    step: "2",
                    text: "Choose learning and reward apps"
                )
                
                NextStepItem(
                    step: "3",
                    text: "Let your child start learning and earning rewards!"
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Supporting Views

struct ProgressIndicator: View {
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index <= currentPage ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut, value: currentPage)
            }
        }
        .padding()
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct FeatureCard: View {
    let step: String
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Step Number
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                
                Text(step)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct PermissionItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

struct NotificationItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

struct NextStepItem: View {
    let step: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 24, height: 24)
                
                Text(step)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthenticationManager())
        .environmentObject(FamilyControlsManager())
        .environmentObject(NotificationManager())
}