//
//  ChildDashboardView.swift
//  BrainCoinz
//
//  Dashboard view for children to see their progress, goals, and rewards
//  Provides motivation and visual feedback for learning achievements
//

import SwiftUI
import CoreData

/**
 * Main dashboard view for children showing their learning progress,
 * current goals, and available rewards. Designed to be engaging and
 * motivational to encourage learning behavior.
 */
struct ChildDashboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var deviceActivityManager: DeviceActivityManager
    @EnvironmentObject var managedSettingsManager: ManagedSettingsManager
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LearningGoal.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isActive == true"),
        animation: .default
    ) private var activeGoals: FetchedResults<LearningGoal>
    
    @State private var selectedTab = 0
    @State private var showingCelebration = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Progress Tab
            ProgressView()
                .tabItem {
                    Image(systemName: "chart.pie.fill")
                    Text("Progress")
                }
                .tag(0)
            
            // Goals Tab
            GoalsView()
                .tabItem {
                    Image(systemName: "target")
                    Text("Goals")
                }
                .tag(1)
            
            // Rewards Tab
            RewardsView()
                .tabItem {
                    Image(systemName: "gift.fill")
                    Text("Rewards")
                }
                .tag(2)
        }
        .accentColor(.blue)
        .onReceive(NotificationCenter.default.publisher(for: .goalCompleted)) { _ in
            showingCelebration = true
        }
        .fullScreenCover(isPresented: $showingCelebration) {
            CelebrationView {
                showingCelebration = false
            }
        }
    }
}

/**
 * Progress view showing current learning progress and motivation
 */
struct ProgressView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var deviceActivityManager: DeviceActivityManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Section
                    welcomeSection
                    
                    // Current Progress Circle
                    progressCircleSection
                    
                    // Time Statistics
                    timeStatsSection
                    
                    // Motivation Section
                    motivationSection
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Your Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out") {
                        authManager.signOut()
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
    
    private var welcomeSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hi \(authManager.currentUser?.name ?? "there")! 👋")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Let's learn together today!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    private var progressCircleSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                    .frame(width: 200, height: 200)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: deviceActivityManager.dailyGoalProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: deviceActivityManager.dailyGoalProgress)
                
                // Center content
                VStack(spacing: 4) {
                    Text("\(Int(deviceActivityManager.dailyGoalProgress * 100))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Complete")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress text
            VStack(spacing: 4) {
                Text("\(Int(deviceActivityManager.getCurrentLearningMinutes())) minutes learned")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if deviceActivityManager.getRemainingMinutes() > 0 {
                    Text("\(Int(deviceActivityManager.getRemainingMinutes())) minutes to go!")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                } else {
                    Text("🎉 Goal completed! Great job!")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
    
    private var timeStatsSection: some View {
        HStack(spacing: 16) {
            TimeStatCard(
                title: "Today",
                value: "\(Int(deviceActivityManager.getCurrentLearningMinutes()))",
                unit: "min",
                color: .blue
            )
            
            TimeStatCard(
                title: "This Week",
                value: "\(Int(deviceActivityManager.getWeeklyStats().totalMinutes))",
                unit: "min",
                color: .green
            )
            
            TimeStatCard(
                title: "Average",
                value: "\(Int(deviceActivityManager.getWeeklyStats().averageDailyMinutes))",
                unit: "min/day",
                color: .orange
            )
        }
    }
    
    private var motivationSection: some View {
        VStack(spacing: 12) {
            Text("Keep Going! 💪")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(getMotivationalMessage())
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func getMotivationalMessage() -> String {
        let progress = deviceActivityManager.dailyGoalProgress
        
        switch progress {
        case 0..<0.25:
            return "You're just getting started! Every minute of learning counts."
        case 0.25..<0.5:
            return "Great start! You're making awesome progress."
        case 0.5..<0.75:
            return "Halfway there! You're doing amazing!"
        case 0.75..<1.0:
            return "So close! Just a little more and you'll unlock your rewards!"
        default:
            return "Fantastic! You've completed your goal and earned your rewards!"
        }
    }
}

/**
 * Goals view showing current learning objectives
 */
struct GoalsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LearningGoal.createdAt, ascending: false)],
        animation: .default
    ) private var goals: FetchedResults<LearningGoal>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(goals, id: \.objectID) { goal in
                    ChildGoalCard(goal: goal)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Your Goals")
        }
    }
}

/**
 * Rewards view showing available and unlocked apps
 */
struct RewardsView: View {
    @EnvironmentObject var managedSettingsManager: ManagedSettingsManager
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LearningGoal.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isActive == true"),
        animation: .default
    ) private var activeGoals: FetchedResults<LearningGoal>
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Reward Status Header
                    rewardStatusHeader
                    
                    // Reward Apps Grid
                    if let currentGoal = activeGoals.first {
                        rewardAppsGrid(for: currentGoal)
                    } else {
                        noGoalsMessage
                    }
                }
                .padding()
            }
            .navigationTitle("Your Rewards")
        }
    }
    
    private var rewardStatusHeader: some View {
        VStack(spacing: 12) {
            if managedSettingsManager.isRewardAppsBlocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                
                Text("Rewards Locked")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Complete your learning goals to unlock your reward apps!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: "gift.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                
                Text("Rewards Unlocked! 🎉")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Great job! You can now enjoy your reward apps.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(
            managedSettingsManager.isRewardAppsBlocked ?
            Color.orange.opacity(0.1) : Color.green.opacity(0.1)
        )
        .cornerRadius(16)
    }
    
    private func rewardAppsGrid(for goal: LearningGoal) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            if let rewardApps = goal.rewardApps?.allObjects as? [SelectedApp] {
                ForEach(rewardApps, id: \.objectID) { app in
                    RewardAppCard(
                        app: app,
                        isUnlocked: !managedSettingsManager.isRewardAppsBlocked
                    )
                }
            }
        }
    }
    
    private var noGoalsMessage: some View {
        VStack(spacing: 16) {
            Image(systemName: "target")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Active Goals")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Ask your parent to set up learning goals to unlock rewards!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Supporting Views

struct TimeStatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ChildGoalCard: View {
    let goal: LearningGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Learning Goal")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(goal.targetDurationMinutes) minutes daily")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                if goal.isActive {
                    Image(systemName: "target")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            
            if let learningApps = goal.learningApps?.allObjects as? [SelectedApp] {
                Text("Learning Apps:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(learningApps.prefix(3), id: \.objectID) { app in
                    Text("• \(app.appName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if learningApps.count > 3 {
                    Text("• And \(learningApps.count - 3) more...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct RewardAppCard: View {
    let app: SelectedApp
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // App Icon Placeholder
            RoundedRectangle(cornerRadius: 16)
                .fill(isUnlocked ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: isUnlocked ? "checkmark.circle.fill" : "lock.fill")
                        .font(.title2)
                        .foregroundColor(isUnlocked ? .green : .gray)
                )
            
            Text(app.appName)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(isUnlocked ? .primary : .secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

struct CelebrationView: View {
    let onDismiss: () -> Void
    
    @State private var animateFireworks = false
    
    var body: some View {
        ZStack {
            Color.blue.opacity(0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Celebration Animation
                VStack(spacing: 16) {
                    Text("🎉")
                        .font(.system(size: 100))
                        .scaleEffect(animateFireworks ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                            value: animateFireworks
                        )
                    
                    Text("Goal Completed!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Amazing work! Your reward apps are now unlocked!")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }
                
                Button("Continue") {
                    onDismiss()
                }
                .font(.headline)
                .foregroundColor(.blue)
                .padding(.horizontal, 40)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(25)
            }
            .padding()
        }
        .onAppear {
            animateFireworks = true
        }
    }
}

#Preview {
    ChildDashboardView()
        .environmentObject(AuthenticationManager())
        .environmentObject(DeviceActivityManager())
        .environmentObject(ManagedSettingsManager())
}