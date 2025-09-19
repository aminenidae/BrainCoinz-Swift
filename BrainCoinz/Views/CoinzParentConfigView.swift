//
//  CoinzParentConfigView.swift
//  BrainCoinz
//
//  Parent interface for configuring Coinz earning rates, app categories, and reward settings
//

import SwiftUI

/**
 * Parent configuration interface for managing the Coinz system
 * Allows parents to customize earning rates per app based on educational priorities
 */
struct CoinzParentConfigView: View {
    @EnvironmentObject var coinzManager: CoinzManager
    @State private var selectedTab = 0
    @State private var showingAddApp = false
    @State private var selectedApp: AppCoinzConfig?
    @State private var showingAppEditor = false
    
    // Balance management dialog states
    @State private var showingBonusDialog = false
    @State private var showingPenaltyDialog = false
    @State private var showingResetDialog = false
    @State private var showingIncreaseDialog = false
    @State private var showingDecreaseDialog = false
    @State private var bonusAmount = 50
    @State private var penaltyAmount = 25
    @State private var adjustmentAmount = 100
    @State private var customReason = ""
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Learning requirements and apps configuration
                learningConfigView
                    .tabItem {
                        Image(systemName: "book.fill")
                        Text("Learning")
                    }
                    .tag(0)
                
                // Reward apps configuration
                rewardAppsConfigView
                    .tabItem {
                        Image(systemName: "gamecontroller.fill")
                        Text("Reward Apps")
                    }
                    .tag(1)
                
                // Goals management
                goalsManagementView
                    .tabItem {
                        Image(systemName: "target")
                        Text("Goals")
                    }
                    .tag(2)
                
                // Statistics and insights
                statisticsView
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("Stats")
                    }
                    .tag(3)
            }
            .navigationTitle("Coinz Configuration")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingAppEditor) {
            if let app = selectedApp {
                AppConfigEditorView(appConfig: app) { updatedApp in
                    coinzManager.updateAppConfig(updatedApp)
                }
            }
        }
        .alert("Award Bonus Coinz", isPresented: $showingBonusDialog) {
            TextField("Amount", value: $bonusAmount, format: .number)
            TextField("Reason", text: $customReason)
            Button("Cancel", role: .cancel) { }
            Button("Award") {
                coinzManager.increaseCoinzBalance(bonusAmount, reason: customReason.isEmpty ? "Parent Bonus" : customReason)
                customReason = ""
            }
        } message: {
            Text("Award bonus Coinz to your child for good behavior or achievements.")
        }
        .alert("Apply Penalty", isPresented: $showingPenaltyDialog) {
            TextField("Amount", value: $penaltyAmount, format: .number)
            TextField("Reason", text: $customReason)
            Button("Cancel", role: .cancel) { }
            Button("Apply", role: .destructive) {
                coinzManager.decreaseCoinzBalance(penaltyAmount, reason: customReason.isEmpty ? "Parent Penalty" : customReason)
                customReason = ""
            }
        } message: {
            Text("Deduct Coinz from your child's balance for violations or inappropriate behavior.")
        }
        .alert("Reset Balance", isPresented: $showingResetDialog) {
            Button("Cancel", role: .cancel) { }
            Button("Reset to 0", role: .destructive) {
                coinzManager.resetCoinzBalance(to: 0)
            }
            Button("Reset to 100") {
                coinzManager.resetCoinzBalance(to: 100)
            }
        } message: {
            Text("Reset your child's Coinz balance. This action cannot be undone.")
        }
        .alert("Increase Balance", isPresented: $showingIncreaseDialog) {
            TextField("Amount", value: $adjustmentAmount, format: .number)
            TextField("Reason", text: $customReason)
            Button("Cancel", role: .cancel) { }
            Button("Increase") {
                coinzManager.increaseCoinzBalance(adjustmentAmount, reason: customReason.isEmpty ? "Parent Adjustment" : customReason)
                customReason = ""
            }
        } message: {
            Text("Add Coinz to your child's balance.")
        }
        .alert("Decrease Balance", isPresented: $showingDecreaseDialog) {
            TextField("Amount", value: $adjustmentAmount, format: .number)
            TextField("Reason", text: $customReason)
            Button("Cancel", role: .cancel) { }
            Button("Decrease", role: .destructive) {
                coinzManager.decreaseCoinzBalance(adjustmentAmount, reason: customReason.isEmpty ? "Parent Adjustment" : customReason)
                customReason = ""
            }
        } message: {
            Text("Remove Coinz from your child's balance.")
        }
    }
    
    // MARK: - Learning Config View (combines requirements and apps)
    private var learningConfigView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Minimum learning time requirement
                minimumLearningTimeCard
                
                // Learning apps configuration
                learningAppsSection
            }
            .padding()
        }
    }
    
    // MARK: - Minimum Learning Time Card
    private var minimumLearningTimeCard: some View {
        let stats = coinzManager.getWalletStats()
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Learning Requirement")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Set minimum time kids must spend on learning apps")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Minimum Daily Learning Time")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(stats.minimumLearningMinutes) minutes")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                // Quick preset buttons
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                    ForEach([5, 10, 15, 30], id: \.self) { minutes in
                        Button("\(minutes)m") {
                            coinzManager.updateMinimumLearningTime(minutes)
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(stats.minimumLearningMinutes == minutes ? .white : .blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(stats.minimumLearningMinutes == minutes ? Color.blue : Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // Custom time slider
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("0m")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Slider(value: .constant(Double(stats.minimumLearningMinutes)), 
                               in: 0...60, 
                               step: 5) { _ in
                            // Update minimum learning time
                        }
                        .accentColor(.blue)
                        
                        Text("60m")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Current progress indicator
            if stats.dailyLearningMinutes > 0 {
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(stats.dailyLearningMinutes) / \(stats.minimumLearningMinutes) minutes")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    CircularProgressView(progress: stats.learningProgressPercentage)
                        .frame(width: 40, height: 40)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Learning Apps Section
    private var learningAppsSection: some View {
        VStack(spacing: 16) {
            // Header with explanation
            configHeaderView(
                title: "📚 Learning Apps",
                subtitle: "Set how many Coinz kids earn per minute",
                explanation: "Higher rates encourage more time on priority educational apps like coding or math."
            )
            
            // Quick rate presets
            learningRatePresets
            
            // App list
            LazyVStack(spacing: 12) {
                ForEach(coinzManager.getLearningApps()) { app in
                    LearningAppConfigCard(appConfig: app) {
                        selectedApp = app
                        showingAppEditor = true
                    }
                }
            }
        }
    }
    
    // MARK: - Learning Apps Config View (legacy - now part of learningConfigView)
    private var learningAppsConfigView: some View {
        // Legacy method - redirect to new combined view
        learningConfigView
    }
    
    // MARK: - Reward Apps Config View
    private var rewardAppsConfigView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header with explanation
                configHeaderView(
                    title: "🎮 Reward Apps",
                    subtitle: "Set how many Coinz kids spend per minute",
                    explanation: "Higher costs discourage overuse of entertainment apps while still allowing earned rewards."
                )
                
                // Quick cost presets
                rewardCostPresets
                
                // Daily time limits management
                dailyTimeLimitsSection
                
                // App list
                LazyVStack(spacing: 12) {
                    ForEach(coinzManager.getRewardApps()) { app in
                        RewardAppConfigCard(appConfig: app) {
                            selectedApp = app
                            showingAppEditor = true
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Goals Management View
    private var goalsManagementView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                configHeaderView(
                    title: "🎯 Learning Goals",
                    subtitle: "Create motivating challenges for your kids",
                    explanation: "Set specific learning targets with bonus rewards to encourage focused educational activities."
                )
                
                // Create goal button
                Button(action: {
                    // Navigate to goal creation
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create New Goal")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                // Active goals
                VStack(alignment: .leading, spacing: 12) {
                    Text("Active Goals")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(coinzManager.activeGoals) { goal in
                        ParentGoalCard(goal: goal)
                    }
                    
                    if coinzManager.activeGoals.isEmpty {
                        Text("No active goals. Create one to motivate your child!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Statistics View
    private var statisticsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Wallet overview
                walletOverviewCard
                
                // Learning insights
                learningInsightsCard
                
                // App usage breakdown
                appUsageBreakdownCard
                
                // Parent actions
                parentActionsCard
            }
            .padding()
        }
    }
    
    // MARK: - Supporting Views
    
    private func configHeaderView(title: String, subtitle: String, explanation: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(explanation)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
    
    private var learningRatePresets: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Rate Presets")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                PresetButton(
                    title: "Standard Rate",
                    subtitle: "1 Coinz/min",
                    color: .blue
                ) {
                    applyLearningPreset(.standard)
                }
                
                PresetButton(
                    title: "High Priority",
                    subtitle: "3 Coinz/min",
                    color: .green
                ) {
                    applyLearningPreset(.high)
                }
                
                PresetButton(
                    title: "Premium Focus",
                    subtitle: "5 Coinz/min",
                    color: .purple
                ) {
                    applyLearningPreset(.premium)
                }
                
                PresetButton(
                    title: "Custom Rates",
                    subtitle: "Mix & match",
                    color: .orange
                ) {
                    applyLearningPreset(.custom)
                }
            }
        }
    }
    
    private var rewardCostPresets: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Cost Presets")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                PresetButton(
                    title: "Gentle Cost",
                    subtitle: "2 Coinz/min",
                    color: .green
                ) {
                    applyRewardPreset(.gentle)
                }
                
                PresetButton(
                    title: "Balanced Cost",
                    subtitle: "5 Coinz/min",
                    color: .blue
                ) {
                    applyRewardPreset(.balanced)
                }
                
                PresetButton(
                    title: "High Cost",
                    subtitle: "8 Coinz/min",
                    color: .orange
                ) {
                    applyRewardPreset(.high)
                }
                
                PresetButton(
                    title: "Custom Costs",
                    subtitle: "Customize each",
                    color: .purple
                ) {
                    applyRewardPreset(.custom)
                }
            }
        }
    }
    
    private var dailyTimeLimitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            VStack(alignment: .leading, spacing: 8) {
                Text("⏰ Daily Time Limits")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Set daily time limits to balance Coinz rewards with healthy screen time")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Usage statistics today
            dailyTimeUsageCard
            
            // Time limit presets
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Limit Presets")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                    ForEach([15, 30, 60, 120], id: \.self) { minutes in
                        Button("\(minutes)m") {
                            applyTimeLimitPreset(minutes)
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Button("No Limit") {
                        applyTimeLimitPreset(0)
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // Individual app time limits
            VStack(alignment: .leading, spacing: 12) {
                Text("Individual App Limits")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVStack(spacing: 8) {
                    ForEach(coinzManager.getRewardApps()) { app in
                        TimeLimitRow(appConfig: app) { updatedApp in
                            coinzManager.updateAppConfig(updatedApp)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var dailyTimeUsageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                
                Text("Today's Usage")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(getCurrentTimeString())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Show usage stats for each reward app
            let usageStats = coinzManager.getDailyTimeUsageStats()
            
            if usageStats.isEmpty {
                Text("No reward apps used today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(usageStats, id: \.bundleID) { stat in
                        HStack {
                            Text(stat.appName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(stat.usedMinutes) / \(stat.limitMinutes > 0 ? "\(stat.limitMinutes)" : "∞") min")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(stat.remainingMinutes == 0 ? .red : .primary)
                                
                                if stat.limitMinutes > 0 {
                                    ProgressView(value: Double(stat.usedMinutes), total: Double(stat.limitMinutes))
                                        .frame(width: 60)
                                        .tint(stat.remainingMinutes == 0 ? .red : stat.remainingMinutes < 10 ? .orange : .green)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(stat.remainingMinutes == 0 ? Color.red.opacity(0.1) : Color.clear)
                        .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    private var walletOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("💰 Child's Wallet Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            let stats = coinzManager.getWalletStats()
            
            // Carryover balance indicator (if any)
            if stats.hasCarryover {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Carryover Balance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(stats.carryoverBalance) Coinz from previous days")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.purple)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(8)
            }
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(stats.balance)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Current Balance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                VStack {
                    Text("\(stats.totalEarned)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    Text("Total Earned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                VStack {
                    Text("\(stats.totalSpent)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    Text("Total Spent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 60)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var learningInsightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 Learning Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Most used learning app
            VStack(alignment: .leading, spacing: 8) {
                Text("Most Popular Learning App")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "book.fill")
                        .foregroundColor(.green)
                    Text("Khan Academy Kids")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("45 min today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Learning streak
            VStack(alignment: .leading, spacing: 8) {
                Text("Learning Streak")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("7 days")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("Great job!")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var appUsageBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📱 App Usage Today")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Sample usage data
            AppUsageRow(appName: "Khan Academy", time: "45 min", earned: 45, color: .green)
            AppUsageRow(appName: "Scratch Jr", time: "20 min", earned: 100, color: .purple)
            AppUsageRow(appName: "YouTube Kids", time: "15 min", earned: -75, color: .red)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var parentActionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🎁 Parent Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ActionButton(
                    title: "Award Bonus",
                    icon: "gift.fill",
                    color: .green
                ) {
                    showBonusDialog()
                }
                
                ActionButton(
                    title: "Apply Penalty",
                    icon: "minus.circle.fill",
                    color: .red
                ) {
                    showPenaltyDialog()
                }
                
                ActionButton(
                    title: "Reset Balance",
                    icon: "arrow.clockwise",
                    color: .blue
                ) {
                    showResetBalanceDialog()
                }
                
                ActionButton(
                    title: "Increase Balance",
                    icon: "plus.circle.fill",
                    color: .green
                ) {
                    showIncreaseBalanceDialog()
                }
                
                ActionButton(
                    title: "Decrease Balance",
                    icon: "minus.circle.fill",
                    color: .orange
                ) {
                    showDecreaseBalanceDialog()
                }
                
                ActionButton(
                    title: "Export Data",
                    icon: "square.and.arrow.up",
                    color: .purple
                ) {
                    exportData()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Action Methods
    
    private func showBonusDialog() {
        bonusAmount = 50
        customReason = ""
        showingBonusDialog = true
    }
    
    private func showPenaltyDialog() {
        penaltyAmount = 25
        customReason = ""
        showingPenaltyDialog = true
    }
    
    private func showResetBalanceDialog() {
        showingResetDialog = true
    }
    
    private func showIncreaseBalanceDialog() {
        adjustmentAmount = 100
        customReason = ""
        showingIncreaseDialog = true
    }
    
    private func showDecreaseBalanceDialog() {
        adjustmentAmount = 50
        customReason = ""
        showingDecreaseDialog = true
    }
    
    private func applyLearningPreset(_ preset: LearningPreset) {
        let rates: [String: Int]
        
        switch preset {
        case .standard:
            rates = [:] // Use default 1 Coinz/min for all
        case .high:
            rates = ["com.flashmath.app": 3, "com.duolingo.duolingoapp": 3]
        case .premium:
            rates = ["org.scratch.scratchjr": 5, "com.apple.swift.playgrounds": 5]
        case .custom:
            rates = PredefinedApps.createCustomLearningRates()
        }
        
        // Apply rates to apps
        for i in 0..<coinzManager.appConfigurations.count {
            if coinzManager.appConfigurations[i].category == .learning {
                if let customRate = rates[coinzManager.appConfigurations[i].bundleID] {
                    coinzManager.appConfigurations[i].coinzRate = customRate
                } else if preset == .standard {
                    coinzManager.appConfigurations[i].coinzRate = 1
                }
            }
        }
    }
    
    private func applyRewardPreset(_ preset: RewardPreset) {
        let defaultCost: Int
        
        switch preset {
        case .gentle: defaultCost = -2
        case .balanced: defaultCost = -5
        case .high: defaultCost = -8
        case .custom: 
            let customRates = PredefinedApps.createCustomRewardRates()
            for i in 0..<coinzManager.appConfigurations.count {
                if coinzManager.appConfigurations[i].category == .reward {
                    if let customRate = customRates[coinzManager.appConfigurations[i].bundleID] {
                        coinzManager.appConfigurations[i].coinzRate = customRate
                    }
                }
            }
            return
        }
        
        // Apply default cost to all reward apps
        for i in 0..<coinzManager.appConfigurations.count {
            if coinzManager.appConfigurations[i].category == .reward {
                coinzManager.appConfigurations[i].coinzRate = defaultCost
            }
        }
    }
    
    private func exportData() {
        // Implementation for exporting usage data
    }
    
    // MARK: - Time Limit Management
    
    private func applyTimeLimitPreset(_ minutes: Int) {
        // Apply the same time limit to all reward apps
        for i in 0..<coinzManager.appConfigurations.count {
            if coinzManager.appConfigurations[i].category == .reward {
                coinzManager.appConfigurations[i].dailyTimeLimit = minutes
                coinzManager.updateAppConfig(coinzManager.appConfigurations[i])
            }
        }
    }
    
    private func getCurrentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    
    // MARK: - Types
    enum LearningPreset {
        case standard, high, premium, custom
    }
    
    enum RewardPreset {
        case gentle, balanced, high, custom
    }
}

// MARK: - Supporting Components

/**
 * Learning app configuration card
 */
struct LearningAppConfigCard: View {
    let appConfig: AppCoinzConfig
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // App icon
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "book.fill")
                            .foregroundColor(.green)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(appConfig.displayName)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Earning Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\\(appConfig.coinzRate)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Coinz/min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

/**
 * Reward app configuration card
 */
struct RewardAppConfigCard: View {
    let appConfig: AppCoinzConfig
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // App icon
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "gamecontroller.fill")
                            .foregroundColor(.orange)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(appConfig.displayName)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Cost Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\\(abs(appConfig.coinzRate))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("Coinz/min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

/**
 * Preset configuration button
 */
struct PresetButton: View {
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

/**
 * Time limit configuration row for individual apps
 */
struct TimeLimitRow: View {
    let appConfig: AppCoinzConfig
    let onUpdate: (AppCoinzConfig) -> Void
    
    @State private var selectedLimit: Int
    
    init(appConfig: AppCoinzConfig, onUpdate: @escaping (AppCoinzConfig) -> Void) {
        self.appConfig = appConfig
        self.onUpdate = onUpdate
        self._selectedLimit = State(initialValue: appConfig.dailyTimeLimit)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // App icon and name
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "gamecontroller.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    )
                
                Text(appConfig.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Time limit picker
            Menu {
                Button("No Limit") {
                    updateTimeLimit(0)
                }
                
                ForEach([15, 30, 45, 60, 90, 120], id: \.self) { minutes in
                    Button("\(minutes) minutes") {
                        updateTimeLimit(minutes)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedLimit == 0 ? "No Limit" : "\(selectedLimit)m")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedLimit == 0 ? .orange : .blue)
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
    }
    
    private func updateTimeLimit(_ minutes: Int) {
        selectedLimit = minutes
        var updatedConfig = appConfig
        updatedConfig.dailyTimeLimit = minutes
        onUpdate(updatedConfig)
    }
}

/**
 * Parent goal card
 */
struct ParentGoalCard: View {
    let goal: CoinzGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Target: \\(goal.targetCoinz) Coinz • Bonus: \\(goal.bonusCoinz) Coinz")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if goal.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            
            ProgressView(value: goal.completionPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            HStack {
                Text("\\(goal.progress)/\\(goal.targetCoinz) Coinz (\\(Int(goal.completionPercentage * 100))%)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Ends: \\(goal.endDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

/**
 * App usage row
 */
struct AppUsageRow: View {
    let appName: String
    let time: String
    let earned: Int
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(appName)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\\(earned > 0 ? "+" : "")\\(earned)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(earned > 0 ? .green : .red)
        }
    }
}

/**
 * Action button component
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
 * App configuration editor view
 */
struct AppConfigEditorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var editableConfig: AppCoinzConfig
    let onSave: (AppCoinzConfig) -> Void
    
    init(appConfig: AppCoinzConfig, onSave: @escaping (AppCoinzConfig) -> Void) {
        self._editableConfig = State(initialValue: appConfig)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("App Information") {
                    HStack {
                        Text("App Name")
                        Spacer()
                        Text(editableConfig.displayName)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Category")
                        Spacer()
                        Text(editableConfig.category.displayName)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(editableConfig.category == .learning ? "Earning Rate" : "Cost Rate") {
                    HStack {
                        Text(editableConfig.category == .learning ? "Coinz earned per minute" : "Coinz cost per minute")
                        Spacer()
                        TextField("Rate", value: $editableConfig.coinzRate, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                    
                    Text(editableConfig.category == .learning ? 
                         "Higher values encourage more time on this app" : 
                         "Higher values discourage overuse of this app")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Status") {
                    Toggle("App Enabled", isOn: $editableConfig.isEnabled)
                }
            }
            .navigationTitle("Edit App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(editableConfig)
                        dismiss()
                    }
                }
            }
        }
    }
}

/**
 * Circular progress view for learning progress
 */
struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 3)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(progress))
                .stroke(progress >= 1.0 ? Color.green : Color.blue, 
                       style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(progress >= 1.0 ? .green : .blue)
        }
    }
}

#Preview {
    CoinzParentConfigView()
        .environmentObject(CoinzManager())
}