//
//  FamilyManagementView.swift
//  BrainCoinz
//
//  Created for v3.0.0 Multi-Family Support
//  Manages family members, invitations, and permissions
//

import SwiftUI
import CloudKit

struct FamilyManagementView: View {
    @EnvironmentObject private var sharedFamilyManager: SharedFamilyManager
    @State private var showingInviteSheet = false
    @State private var inviteEmail = ""
    @State private var invitePhone = ""
    @State private var inviteRole: FamilyRole = .parent
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showAlert = false
    @State private var selectedMember: FamilyMember?
    
    var body: some View {
        NavigationView {
            List {
                if let family = sharedFamilyManager.currentFamily {
                    familyInfoSection(family)
                    familyMembersSection
                    pendingInvitationsSection
                    familyActionsSection
                } else {
                    noFamilySection
                }
            }
            .navigationTitle("Family Management")
            .toolbar {
                if sharedFamilyManager.currentFamily != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingInviteSheet = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingInviteSheet) {
                inviteMemberSheet
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Family Info Section
    private func familyInfoSection(_ family: SharedFamily) -> some View {
        Section("Family Information") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "house.fill")
                        .foregroundColor(.blue)
                    Text(family.name)
                        .font(.headline)
                }
                
                HStack {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .foregroundColor(.green)
                    Text("Organizer: \(family.organizerName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.gray)
                    Text("Created: \(family.creationDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Family Members Section
    private var familyMembersSection: some View {
        Section("Family Members") {
            ForEach(sharedFamilyManager.familyMembers) { member in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(member.name)
                            .font(.headline)
                        
                        HStack {
                            roleIcon(for: member.role)
                            Text(member.role.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if member.isCurrentUser {
                            Text("You")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(member.isOnline ? "Online" : "Offline")
                            .font(.caption)
                            .foregroundColor(member.isOnline ? .green : .gray)
                        
                        Circle()
                            .fill(member.isOnline ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedMember = member
                }
            }
        }
    }
    
    // MARK: - Pending Invitations Section
    private var pendingInvitationsSection: some View {
        Section("Pending Invitations") {
            if sharedFamilyManager.pendingInvitations.isEmpty {
                Text("No pending invitations")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                ForEach(sharedFamilyManager.pendingInvitations) { invitation in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(invitation.inviteeEmail)
                                .font(.headline)
                            
                            HStack {
                                roleIcon(for: invitation.role)
                                Text(invitation.role.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Sent: \(invitation.sentDate, style: .relative)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button("Resend") {
                            resendInvitation(invitation)
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    // MARK: - Family Actions Section
    private var familyActionsSection: some View {
        Section("Actions") {
            if sharedFamilyManager.canManageFamily {
                Button(action: {
                    showingInviteSheet = true
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Invite Family Member")
                    }
                }
                
                Button(action: exportFamilyData) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Family Data")
                    }
                }
            }
            
            Button(action: refreshFamilyData) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh Family Data")
                }
            }
            
            Button(action: leaveFamilyAction) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Leave Family")
                }
                .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - No Family Section
    private var noFamilySection: some View {
        Section {
            VStack(spacing: 15) {
                Image(systemName: "person.3")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
                
                Text("No Family Setup")
                    .font(.headline)
                
                Text("Create or join a family to start managing screen time across multiple devices.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                NavigationLink(destination: FamilySetupView()) {
                    Text("Setup Family")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Invite Member Sheet
    private var inviteMemberSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Invite Family Member")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email Address")
                            .font(.headline)
                        TextField("Enter email address", text: $inviteEmail)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone Number (Optional)")
                            .font(.headline)
                        TextField("Enter phone number", text: $invitePhone)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.phonePad)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Role")
                            .font(.headline)
                        
                        Picker("Role", selection: $inviteRole) {
                            Text("Parent").tag(FamilyRole.parent)
                            Text("Guardian").tag(FamilyRole.guardian)
                            Text("Child").tag(FamilyRole.child)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Invite Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingInviteSheet = false
                        resetInviteForm()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        sendInvitation()
                    }
                    .disabled(inviteEmail.isEmpty || isLoading)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func roleIcon(for role: FamilyRole) -> some View {
        let iconName: String
        let color: Color
        
        switch role {
        case .organizer:
            iconName = "crown.fill"
            color = .orange
        case .parent:
            iconName = "person.fill"
            color = .blue
        case .guardian:
            iconName = "shield.fill"
            color = .green
        case .child:
            iconName = "person.crop.circle"
            color = .purple
        }
        
        return Image(systemName: iconName)
            .foregroundColor(color)
    }
    
    // MARK: - Actions
    private func sendInvitation() {
        isLoading = true
        errorMessage = ""
        
        let phone = invitePhone.isEmpty ? nil : invitePhone
        
        sharedFamilyManager.inviteFamilyMember(email: inviteEmail, phone: phone, role: inviteRole) { success, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if success {
                    showingInviteSheet = false
                    resetInviteForm()
                } else {
                    errorMessage = error?.localizedDescription ?? "Failed to send invitation"
                    showAlert = true
                }
            }
        }
    }
    
    private func resendInvitation(_ invitation: FamilyInvitation) {
        sharedFamilyManager.resendInvitation(invitation.id) { success, error in
            DispatchQueue.main.async {
                if !success {
                    errorMessage = error?.localizedDescription ?? "Failed to resend invitation"
                    showAlert = true
                }
            }
        }
    }
    
    private func exportFamilyData() {
        // Implementation for exporting family data
        // This would typically create a file with family settings and configurations
    }
    
    private func refreshFamilyData() {
        sharedFamilyManager.refreshFamilyData { success, error in
            DispatchQueue.main.async {
                if !success {
                    errorMessage = error?.localizedDescription ?? "Failed to refresh family data"
                    showAlert = true
                }
            }
        }
    }
    
    private func leaveFamilyAction() {
        // Show confirmation alert for leaving family
        let alert = UIAlertController(title: "Leave Family", 
                                    message: "Are you sure you want to leave this family? This action cannot be undone.", 
                                    preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Leave", style: .destructive) { _ in
            sharedFamilyManager.leaveFamily { success, error in
                DispatchQueue.main.async {
                    if !success {
                        errorMessage = error?.localizedDescription ?? "Failed to leave family"
                        showAlert = true
                    }
                }
            }
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    private func resetInviteForm() {
        inviteEmail = ""
        invitePhone = ""
        inviteRole = .parent
    }
}

struct FamilyManagementView_Previews: PreviewProvider {
    static var previews: some View {
        FamilyManagementView()
            .environmentObject(SharedFamilyManager())
    }
}