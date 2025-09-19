//
//  RewardAppUnlockView.swift
//  BrainCoinz
//
//  Interface for unlocking reward apps with Coinz
//

import SwiftUI

/**
 * Modal view for unlocking reward apps by spending Coinz
 * Shows cost, available time, and confirmation interface
 */
struct RewardAppUnlockView: View {
    @EnvironmentObject var coinzManager: CoinzManager
    @Environment(\.dismiss) var dismiss
    
    let appConfig: AppCoinzConfig
    @State private var selectedMinutes = 10
    @State private var showingConfirmation = false
    
    private let timeOptions = [5, 10, 15, 30, 60]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // App header
                appHeaderView
                
                // Cost calculator
                costCalculatorView
                
                // Time selector
                timeSelectorView
                
                // Balance info
                balanceInfoView
                
                Spacer()
                
                // Action buttons
                actionButtonsView
            }
            .padding()
            .navigationTitle("Unlock App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Confirm Purchase", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Unlock") {
                unlockApp()
            }
        } message: {
            Text("Spend \\(totalCost) Coinz to unlock \\(appConfig.displayName) for \\(selectedMinutes) minutes?")
        }
    }
    
    private var totalCost: Int {
        abs(appConfig.coinzRate) * selectedMinutes
    }
    
    private var canAfford: Bool {
        guard let wallet = coinzManager.currentWallet else { return false }
        let hasEnoughCoinz = wallet.currentBalance >= totalCost
        let hasMetLearningRequirement = wallet.hasMetDailyLearningRequirement
        return hasEnoughCoinz && hasMetLearningRequirement
    }
    
    // MARK: - App Header View
    private var appHeaderView: some View {
        VStack(spacing: 16) {
            // App icon placeholder
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.orange.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                )
            
            VStack(spacing: 4) {
                Text(appConfig.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Reward App")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Cost Calculator View
    private var costCalculatorView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Cost per minute:")
                    .font(.headline)
                Spacer()
                Text("\\(abs(appConfig.coinzRate)) Coinz")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
            
            Divider()
            
            HStack {
                Text("Total cost:")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Text("\\(totalCost) Coinz")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Time Selector View
    private var timeSelectorView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select time to unlock:")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(timeOptions, id: \\.self) { minutes in
                    TimeOptionButton(
                        minutes: minutes,
                        isSelected: selectedMinutes == minutes,
                        cost: abs(appConfig.coinzRate) * minutes,
                        canAfford: (coinzManager.currentWallet?.currentBalance ?? 0) >= (abs(appConfig.coinzRate) * minutes)
                    ) {
                        selectedMinutes = minutes
                    }
                }
            }
        }
    }
    
    // MARK: - Balance Info View
    private var balanceInfoView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.blue)
                Text("Your Balance:")
                    .font(.subheadline)
                Spacer()
                Text("\\(coinzManager.currentWallet?.currentBalance ?? 0) Coinz")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            if !canAfford {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Need \\(totalCost - (coinzManager.currentWallet?.currentBalance ?? 0)) more Coinz")
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
            }
        }
        .padding()
        .background(canAfford ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Action Buttons View
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            if canAfford {
                Button(action: {
                    showingConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "lock.open.fill")
                        Text("Unlock for \\(selectedMinutes) minutes")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
                }
            } else {
                VStack(spacing: 8) {
                    Button(action: {
                        dismiss()
                        // Navigate to learning apps
                    }) {
                        HStack {
                            Image(systemName: "book.fill")
                            Text("Earn More Coinz")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    
                    Text("Use learning apps to earn the Coinz you need!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    // MARK: - Actions
    private func unlockApp() {
        if coinzManager.spendCoinzForRewardApp(appConfig, minutes: selectedMinutes) {
            dismiss()
        }
    }
}

/**
 * Time option button component
 */
struct TimeOptionButton: View {
    let minutes: Int
    let isSelected: Bool
    let cost: Int
    let canAfford: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text("\\(minutes) min")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\\(cost) Coinz")
                    .font(.caption)
                    .foregroundColor(canAfford ? .secondary : .red)
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue : (canAfford ? Color(.systemGray6) : Color.red.opacity(0.1)))
            .foregroundColor(isSelected ? .white : (canAfford ? .primary : .red))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : (canAfford ? Color.gray.opacity(0.3) : Color.red), lineWidth: 1)
            )
        }
        .disabled(!canAfford)
    }
}

/**
 * Transaction history view
 */
struct TransactionHistoryView: View {
    @EnvironmentObject var coinzManager: CoinzManager
    @State private var selectedFilter: TransactionFilter = .all
    
    enum TransactionFilter: String, CaseIterable {
        case all = "All"
        case earned = "Earned"
        case spent = "Spent"
        case bonus = "Bonus"
        case penalty = "Penalty"
        case adjustment = "Adjustment"
    }
    
    var filteredTransactions: [CoinzTransaction] {
        switch selectedFilter {
        case .all:
            return coinzManager.recentTransactions
        case .earned:
            return coinzManager.recentTransactions.filter { $0.transactionType == .earned }
        case .spent:
            return coinzManager.recentTransactions.filter { $0.transactionType == .spent }
        case .bonus:
            return coinzManager.recentTransactions.filter { $0.transactionType == .bonus }
        case .penalty:
            return coinzManager.recentTransactions.filter { $0.transactionType == .penalty }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(TransactionFilter.allCases, id: \\.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Transaction list
                List {
                    ForEach(filteredTransactions) { transaction in
                        TransactionDetailRow(transaction: transaction)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Transaction History")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

/**
 * Detailed transaction row
 */
struct TransactionDetailRow: View {
    let transaction: CoinzTransaction
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Transaction type icon
                Image(systemName: transaction.transactionType.iconName)
                    .font(.title2)
                    .foregroundColor(transaction.transactionType.color == "green" ? .green : .red)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.appDisplayName)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(transaction.transactionType.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\\(transaction.coinzAmount > 0 ? "+" : "")\\(transaction.coinzAmount)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(transaction.coinzAmount > 0 ? .green : .red)
                    
                    if transaction.timeSpentMinutes > 0 {
                        Text("\\(transaction.timeSpentMinutes) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            HStack {
                Text(transaction.timestamp, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(transaction.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RewardAppUnlockView(appConfig: AppCoinzConfig(bundleID: "test", displayName: "Test Game", category: .reward))
        .environmentObject(CoinzManager())
}