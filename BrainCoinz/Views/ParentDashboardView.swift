//
//  ParentDashboardView.swift
//  BrainCoinz
//
//  Main dashboard for parents to set up learning goals, select apps, and monitor progress
//  Provides comprehensive parental controls and monitoring capabilities
//

import SwiftUI
import FamilyControls
import CoreData

/**
 * Main dashboard view for parents to manage their child's screen time goals.
 * This view provides access to all parental control features including
 * app selection, goal setting, progress monitoring, and settings management.
 */
struct ParentDashboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var familyControlsManager: FamilyControlsManager
    @EnvironmentObject var deviceActivityManager: DeviceActivityManager
    @EnvironmentObject var managedSettingsManager: ManagedSettingsManager
    @EnvironmentObject var notificationManager: NotificationManager
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LearningGoal.createdAt, ascending: false)],
        animation: .default
    ) private var learningGoals: FetchedResults<LearningGoal>
    
    @State private var selectedTab = 0
    @State private var showingGoalCreation = false
    @State private var showingSettings = false
    @State private var showingAppPicker = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Overview Tab
            DashboardOverviewView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
                .tag(0)
            
            // Goals Management Tab
            GoalsManagementView()
                .tabItem {
                    Image(systemName: "target")
                    Text("Goals")
                }
                .tag(1)
            
            // Progress Monitoring Tab
            ProgressMonitoringView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
                .tag(2)
            
            // Settings Tab
            ParentSettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(.blue)
        .onAppear {
            checkFamilyControlsAuthorization()
        }
    }
    
    /**
     * Checks and requests Family Controls authorization if needed
     */
    private func checkFamilyControlsAuthorization() {
        if !familyControlsManager.isAuthorized {
            Task {
                await familyControlsManager.requestAuthorization()
            }
        }
    }
}

/**
 * Dashboard overview showing current status and quick actions
 */
struct DashboardOverviewView: View {
    @EnvironmentObject var familyControlsManager: FamilyControlsManager
    @EnvironmentObject var deviceActivityManager: DeviceActivityManager
    @EnvironmentObject var managedSettingsManager: ManagedSettingsManager
    @EnvironmentObject var authManager: AuthenticationManager
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LearningGoal.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isActive == true"),
        animation: .default
    ) private var activeGoals: FetchedResults<LearningGoal>
    
    @State private var showingGoalCreation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    welcomeHeader
                    
                    // Quick Stats Cards
                    quickStatsSection
                    
                    // Active Goals Section
                    activeGoalsSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Family Controls Status
                    familyControlsStatusSection
                }
                .padding()
            }
            .navigationTitle("BrainCoinz")
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
        .sheet(isPresented: $showingGoalCreation) {
            GoalCreationView()
        }
    }
    
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Welcome back!")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Manage your family's screen time")
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
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var quickStatsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            StatCard(
                title: "Active Goals",
                value: "\(activeGoals.count)",
                icon: "target",
                color: .green
            )
            
            StatCard(
                title: "Blocked Apps",
                value: "\(managedSettingsManager.blockedAppsCount)",
                icon: "lock.fill",
                color: .red
            )
        }
    }
    
    private var activeGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Goals")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Create New") {
                    showingGoalCreation = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if activeGoals.isEmpty {
                EmptyStateView(
                    icon: "target",
                    title: "No Active Goals",
                    message: "Create a learning goal to get started"
                ) {
                    showingGoalCreation = true
                }
            } else {
                ForEach(activeGoals, id: \.objectID) { goal in
                    GoalSummaryCard(goal: goal)
                }
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionCard(
                    title: "Select Learning Apps",
                    icon: "book.fill",
                    color: .green
                ) {
                    familyControlsManager.selectLearningApps()
                }
                
                QuickActionCard(
                    title: "Select Reward Apps",
                    icon: "gamecontroller.fill",
                    color: .orange
                ) {
                    familyControlsManager.selectRewardApps()
                }
            }
        }
    }
    
    private var familyControlsStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Family Controls Status")
                .font(.headline)
                .fontWeight(.semibold)
            
            StatusCard(
                title: "Authorization",
                status: familyControlsManager.isAuthorized ? "Authorized" : "Not Authorized",
                isPositive: familyControlsManager.isAuthorized,
                action: familyControlsManager.isAuthorized ? nil : {
                    Task {
                        await familyControlsManager.requestAuthorization()
                    }
                }
            )
        }
    }
}

/**
 * Goals management view for creating, editing, and managing learning goals
 */
struct GoalsManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LearningGoal.createdAt, ascending: false)],
        animation: .default
    ) private var allGoals: FetchedResults<LearningGoal>
    
    @State private var showingGoalCreation = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(allGoals, id: \.objectID) { goal in
                    GoalRowView(goal: goal)
                        .swipeActions(edge: .trailing) {
                            Button("Delete", role: .destructive) {
                                deleteGoal(goal)
                            }
                        }
                }
            }
            .navigationTitle("Learning Goals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Goal") {
                        showingGoalCreation = true
                    }
                }
            }
            .sheet(isPresented: $showingGoalCreation) {
                GoalCreationView()
            }
        }
    }
    
    private func deleteGoal(_ goal: LearningGoal) {
        withAnimation {
            viewContext.delete(goal)
            
            do {
                try viewContext.save()
            } catch {
                print("Failed to delete goal: \(error)")
            }
        }
    }
}

/**
 * Progress monitoring view showing detailed usage statistics
 */
struct ProgressMonitoringView: View {
    @EnvironmentObject var deviceActivityManager: DeviceActivityManager
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Progress Card
                    currentProgressCard
                    
                    // Weekly Statistics
                    weeklyStatsCard
                    
                    // Usage History
                    usageHistorySection
                }
                .padding()
            }
            .navigationTitle("Progress")
            .refreshable {
                // Refresh progress data
            }
        }
    }
    
    private var currentProgressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            if deviceActivityManager.isMonitoring {
                VStack(spacing: 12) {
                    ProgressBar(
                        progress: deviceActivityManager.dailyGoalProgress,
                        color: .blue
                    )
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(Int(deviceActivityManager.getCurrentLearningMinutes())) min")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Completed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(Int(deviceActivityManager.getRemainingMinutes())) min")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Remaining")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                Text("No active monitoring")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var weeklyStatsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Statistics")
                .font(.headline)
                .fontWeight(.semibold)
            
            let weeklyStats = deviceActivityManager.getWeeklyStats()
            
            HStack(spacing: 20) {
                StatItem(
                    title: "Total Time",
                    value: "\(Int(weeklyStats.totalMinutes)) min"
                )
                
                StatItem(
                    title: "Daily Average",
                    value: "\(Int(weeklyStats.averageDailyMinutes)) min"
                )
                
                StatItem(
                    title: "Sessions",
                    value: "\(weeklyStats.sessionsCount)"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var usageHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Usage")
                .font(.headline)
                .fontWeight(.semibold)
            
            let recentSessions = deviceActivityManager.getUsageStatistics(
                from: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
                to: Date()
            )
            
            ForEach(recentSessions.prefix(5), id: \.objectID) { session in
                UsageSessionRow(session: session)
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatusCard: View {
    let title: String
    let status: String
    let isPositive: Bool
    let action: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(status)
                    .font(.caption)
                    .foregroundColor(isPositive ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isPositive ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .cornerRadius(8)
            }
            
            if let action = action {
                Button("Fix Issue") {
                    action()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct GoalSummaryCard: View {
    let goal: LearningGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Goal: \(goal.targetDurationMinutes) minutes")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
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
            
            Text("Learning Apps: \(goal.learningApps?.count ?? 0)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Reward Apps: \(goal.rewardApps?.count ?? 0)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Get Started") {
                action()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    ParentDashboardView()
        .environmentObject(AuthenticationManager())
        .environmentObject(FamilyControlsManager())
        .environmentObject(DeviceActivityManager())
        .environmentObject(ManagedSettingsManager())
        .environmentObject(NotificationManager())
}