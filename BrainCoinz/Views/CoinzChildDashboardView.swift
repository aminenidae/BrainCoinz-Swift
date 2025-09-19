//
//  CoinzChildDashboardView.swift
//  BrainCoinz
//
//  Child dashboard showing Coinz balance, earning progress, and available apps
//  Core interface for the gamified learning experience
//

import SwiftUI

/**
 * Main dashboard for children showing their Coinz balance, learning progress,
 * available apps, and reward opportunities. This is the core interface that
 * gamifies the learning experience and motivates children to use educational apps.
 */
struct CoinzChildDashboardView: View {
    @EnvironmentObject var coinzManager: CoinzManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedTab = 0
    @State private var showingAppSelector = false
    @State private var showingRewardUnlock = false
    @State private var selectedRewardApp: AppCoinzConfig?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Main Coinz dashboard
            mainDashboardView
                .tabItem {
                    Image(systemName: "dollarsign.circle.fill")
                    Text("My Coinz")
                }
                .tag(0)
            
            // Learning apps
            learningAppsView
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Learn & Earn")
                }
                .tag(1)
            
            // Reward apps
            rewardAppsView
                .tabItem {
                    Image(systemName: "gamecontroller.fill")
                    Text("Rewards")
                }
                .tag(2)
            
            // Goals and achievements
            goalsView
                .tabItem {
                    Image(systemName: "target")
                    Text("Goals")
                }
                .tag(3)
        }
        .accentColor(.blue)
        .sheet(isPresented: $showingRewardUnlock) {
            if let app = selectedRewardApp {
                RewardAppUnlockView(appConfig: app)
            }
        }
    }
    
    // MARK: - Main Dashboard View
    private var mainDashboardView: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Coinz balance header
                    coinzBalanceCard
                    
                    // Learning progress toward minimum requirement
                    learningProgressCard
                    
                    // Current earning session
                    if coinzManager.isEarningActive {
                        currentEarningCard
                    }
                    
                    // Daily progress
                    dailyProgressCard
                    
                    // Recent transactions
                    recentTransactionsCard
                    
                    // Quick actions
                    quickActionsCard
                }
                .padding()
            }
            .navigationTitle("BrainCoinz")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                // Refresh data
            }
        }
    }
    
    // MARK: - Learning Progress Card
    private var learningProgressCard: some View {
        let stats = coinzManager.getWalletStats()
        let isRequirementMet = stats.dailyLearningMinutes >= stats.minimumLearningMinutes
        let remainingMinutes = max(0, stats.minimumLearningMinutes - stats.dailyLearningMinutes)
        
        return VStack(spacing: 16) {
            HStack {
                Image(systemName: isRequirementMet ? "checkmark.circle.fill" : "clock.fill")
                    .font(.system(size: 24))
                    .foregroundColor(isRequirementMet ? .green : .orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Learning Goal")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if isRequirementMet {
                        Text("\u2713 Goal completed! Reward apps unlocked")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    } else {
                        Text("\(remainingMinutes) minutes remaining to unlock rewards")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(stats.dailyLearningMinutes) / \(stats.minimumLearningMinutes) minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(stats.learningProgressPercentage * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isRequirementMet ? .green : .orange)
                }
                
                ProgressView(value: stats.learningProgressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: isRequirementMet ? .green : .orange))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            
            if !isRequirementMet {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.blue)
                    Text("Use learning apps to complete your daily goal and unlock reward apps!")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(isRequirementMet ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Coinz Balance Card
    private var coinzBalanceCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading) {
                    Text("My Coinz Balance")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("\(coinzManager.currentWallet?.currentBalance ?? 0)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            
            // Carryover balance indicator (if any)
            let stats = coinzManager.getWalletStats()
            if stats.hasCarryover {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.purple)
                    
                    Text("\(stats.carryoverBalance) Coinz carried over from previous days")
                        .font(.caption)
                        .foregroundColor(.purple)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Quick stats
            HStack(spacing: 20) {
                VStack {
                    Text("\\(coinzManager.currentWallet?.dailyEarned ?? 0)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    Text("Earned Today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                VStack {
                    Text("\\(coinzManager.currentWallet?.dailySpent ?? 0)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    Text("Spent Today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                VStack {
                    Text("\\(coinzManager.currentWallet?.totalEarned ?? 0)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    Text("Total Earned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 60)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Current Earning Card
    private var currentEarningCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading) {
                    Text("Currently Learning")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    if let app = coinzManager.currentEarningApp {
                        Text(app.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button("Stop") {
                    coinzManager.endEarningSession()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            // Earning rate info
            if let app = coinzManager.currentEarningApp {
                HStack {
                    Text("Earning \\(app.coinzRate) Coinz per minute")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "timer")
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Daily Progress Card
    private var dailyProgressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Today's Progress")
                    .font(.headline)
                Spacer()
            }
            
            // Progress visualization
            let dailyEarned = coinzManager.currentWallet?.dailyEarned ?? 0
            let dailySpent = coinzManager.currentWallet?.dailySpent ?? 0
            let dailyNet = dailyEarned - dailySpent
            
            HStack(spacing: 16) {
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green)
                        .frame(width: 8, height: max(CGFloat(dailyEarned) * 2, 20))
                    
                    Text("\\(dailyEarned)")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text("Earned")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.orange)
                        .frame(width: 8, height: max(CGFloat(dailySpent) * 2, 20))
                    
                    Text("\\(dailySpent)")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text("Spent")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Net: \\(dailyNet)")
                        .font(.headline)
                        .foregroundColor(dailyNet >= 0 ? .green : .red)
                    
                    Text(dailyNet >= 0 ? "Great job!" : "Earn more!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Recent Transactions Card
    private var recentTransactionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.rectangle")
                    .foregroundColor(.blue)
                Text("Recent Activity")
                    .font(.headline)
                Spacer()
                
                NavigationLink("View All") {
                    TransactionHistoryView()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            ForEach(coinzManager.recentTransactions.prefix(3)) { transaction in
                TransactionRowView(transaction: transaction)
            }
            
            if coinzManager.recentTransactions.isEmpty {
                Text("No recent activity")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Quick Actions Card
    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.orange)
                Text("Quick Actions")
                    .font(.headline)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(
                    title: "Start Learning",
                    icon: "book.fill",
                    color: .green
                ) {
                    selectedTab = 1
                }
                
                QuickActionButton(
                    title: "View Rewards",
                    icon: "gift.fill",
                    color: .orange
                ) {
                    selectedTab = 2
                }
                
                QuickActionButton(
                    title: "Check Goals",
                    icon: "target",
                    color: .blue
                ) {
                    selectedTab = 3
                }
                
                QuickActionButton(
                    title: "My History",
                    icon: "clock.fill",
                    color: .purple
                ) {
                    // Navigate to history
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Learning Apps View
    private var learningAppsView: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(coinzManager.getLearningApps()) { app in
                        LearningAppCard(appConfig: app) {
                            coinzManager.startEarningSession(for: app)
                            selectedTab = 0 // Switch back to main view
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Learning Apps")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Reward Apps View
    private var rewardAppsView: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(coinzManager.getRewardApps()) { app in
                        RewardAppCard(appConfig: app) {
                            selectedRewardApp = app
                            showingRewardUnlock = true
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Reward Apps")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Goals View
    private var goalsView: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(coinzManager.activeGoals) { goal in
                        GoalCard(goal: goal)
                    }
                    
                    if coinzManager.activeGoals.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "target")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("No Active Goals")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Ask your parent to create learning goals for you!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("My Goals")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Supporting Views

/**
 * Quick action button component
 */
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 70)
            .background(color)
            .cornerRadius(12)
        }
    }
}

/**
 * Learning app card
 */
struct LearningAppCard: View {
    let appConfig: AppCoinzConfig
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // App icon placeholder
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "book.fill")
                            .font(.title)
                            .foregroundColor(.green)
                    )
                
                VStack(spacing: 4) {
                    Text(appConfig.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text("\\(appConfig.coinzRate) Coinz/min")
                        .font(.caption)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                }
                
                Text("Tap to Start Learning")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .foregroundColor(.primary)
    }
}

/**
 * Reward app card
 */
struct RewardAppCard: View {
    @EnvironmentObject var coinzManager: CoinzManager
    let appConfig: AppCoinzConfig
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // App icon placeholder
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "gamecontroller.fill")
                            .font(.title)
                            .foregroundColor(.orange)
                    )
                
                VStack(spacing: 4) {
                    Text(appConfig.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text("\\(abs(appConfig.coinzRate)) Coinz/min")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                }
                
                let (canAfford, minutes, learningRequirementMet, remainingDailyTime) = coinzManager.checkAffordability(for: appConfig)
                
                if !learningRequirementMet {
                    VStack(spacing: 2) {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text("Complete learning goal")
                            .font(.caption2)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    // Show the balance between Coinz time and daily limits
                    VStack(spacing: 2) {
                        if remainingDailyTime == 0 {
                            // Daily limit reached
                            VStack(spacing: 1) {
                                Image(systemName: "clock.badge.xmark")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                Text("Daily limit reached")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                        } else if minutes == 0 {
                            // No Coinz available
                            VStack(spacing: 1) {
                                Image(systemName: "dollarsign.circle")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text("Earn more Coinz")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                    .multilineTextAlignment(.center)
                            }
                        } else {
                            // Show available time (limited by both Coinz and daily limits)
                            let coinzAffordableMinutes = (coinzManager.currentWallet?.currentBalance ?? 0) / abs(appConfig.coinzRate)
                            let displayMinutes = min(minutes, remainingDailyTime == Int.max ? minutes : remainingDailyTime)
                            
                            VStack(spacing: 1) {
                                Text("\(displayMinutes) min available")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                    .fontWeight(.medium)
                                
                                // Show limiting factor
                                if remainingDailyTime != Int.max && remainingDailyTime < coinzAffordableMinutes {
                                    Text("(Limited by daily time)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                } else if coinzAffordableMinutes < remainingDailyTime {
                                    Text("(Limited by Coinz)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .foregroundColor(.primary)
    }
}

/**
 * Transaction row view
 */
struct TransactionRowView: View {
    let transaction: CoinzTransaction
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.transactionType.iconName)
                .font(.title3)
                .foregroundColor(transaction.transactionType.color == "green" ? .green : .red)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.appDisplayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(transaction.transactionType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\\(transaction.coinzAmount > 0 ? "+" : "")\\(transaction.coinzAmount)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(transaction.coinzAmount > 0 ? .green : .red)
        }
        .padding(.vertical, 4)
    }
}

/**
 * Goal card view
 */
struct GoalCard: View {
    let goal: CoinzGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(goal.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if goal.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Progress: \\(goal.progress)/\\(goal.targetCoinz) Coinz")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\\(Int(goal.completionPercentage * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                ProgressView(value: goal.completionPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
            
            if goal.bonusCoinz > 0 {
                HStack {
                    Image(systemName: "gift.fill")
                        .foregroundColor(.orange)
                    Text("\\(goal.bonusCoinz) bonus Coinz on completion!")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(goal.isCompleted ? Color.green.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    CoinzChildDashboardView()
        .environmentObject(CoinzManager())
        .environmentObject(AuthenticationManager())
}