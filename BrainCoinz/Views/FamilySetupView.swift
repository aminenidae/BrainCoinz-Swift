//
//  FamilySetupView.swift
//  BrainCoinz
//
//  Created for v3.0.0 Multi-Family Support
//  Handles creating and joining shared families across different iCloud accounts
//

import SwiftUI
import CloudKit

struct FamilySetupView: View {
    @EnvironmentObject private var sharedFamilyManager: SharedFamilyManager
    @State private var setupMode: SetupMode = .chooseMode
    @State private var familyName = ""
    @State private var organizerName = ""
    @State private var invitationCode = ""
    @State private var userRole: FamilyRole = .parent
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showAlert = false
    
    enum SetupMode {
        case chooseMode
        case createFamily
        case joinFamily
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                switch setupMode {
                case .chooseMode:
                    chooseModeView
                case .createFamily:
                    createFamilyView
                case .joinFamily:
                    joinFamilyView
                }
            }
            .padding()
            .navigationTitle("Family Setup")
            .navigationBarTitleDisplayMode(.large)
            .alert("Error", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Choose Mode View
    private var chooseModeView: some View {
        VStack(spacing: 30) {
            VStack(spacing: 15) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Welcome to BrainCoinz Family")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Create a shared family to manage screen time across different devices and iCloud accounts, just like iOS Screen Time.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 15) {
                Button(action: {
                    setupMode = .createFamily
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create New Family")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    setupMode = .joinFamily
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Join Existing Family")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Create Family View
    private var createFamilyView: some View {
        VStack(spacing: 25) {
            VStack(alignment: .leading, spacing: 15) {
                Text("Create Your Family")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("You'll be the family organizer and can invite other parents and add children.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Family Name")
                        .font(.headline)
                    TextField("Enter family name", text: $familyName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Name")
                        .font(.headline)
                    TextField("Enter your name", text: $organizerName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            
            Button(action: createFamily) {
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Creating Family...")
                    }
                } else {
                    Text("Create Family")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(familyName.isEmpty || organizerName.isEmpty ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(familyName.isEmpty || organizerName.isEmpty || isLoading)
            
            Button("Back") {
                setupMode = .chooseMode
            }
            .foregroundColor(.blue)
            
            Spacer()
        }
    }
    
    // MARK: - Join Family View
    private var joinFamilyView: some View {
        VStack(spacing: 25) {
            VStack(alignment: .leading, spacing: 15) {
                Text("Join a Family")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Enter the invitation code you received from a family organizer.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Invitation Code")
                        .font(.headline)
                    TextField("Enter invitation code", text: $invitationCode)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textInputAutocapitalization(.characters)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Role")
                        .font(.headline)
                    
                    Picker("Role", selection: $userRole) {
                        Text("Parent").tag(FamilyRole.parent)
                        Text("Guardian").tag(FamilyRole.guardian)
                        Text("Child").tag(FamilyRole.child)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            
            Button(action: joinFamily) {
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Joining Family...")
                    }
                } else {
                    Text("Join Family")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(invitationCode.isEmpty ? Color.gray : Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(invitationCode.isEmpty || isLoading)
            
            Button("Back") {
                setupMode = .chooseMode
            }
            .foregroundColor(.blue)
            
            Spacer()
        }
    }
    
    // MARK: - Actions
    private func createFamily() {
        isLoading = true
        errorMessage = ""
        
        sharedFamilyManager.createSharedFamily(familyName: familyName, organizerName: organizerName) { success, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if success {
                    // Family created successfully, the view will automatically update
                    // based on sharedFamilyManager.currentFamily state
                } else {
                    errorMessage = error?.localizedDescription ?? "Failed to create family"
                    showAlert = true
                }
            }
        }
    }
    
    private func joinFamily() {
        isLoading = true
        errorMessage = ""
        
        sharedFamilyManager.acceptFamilyInvitation(invitationCode: invitationCode, role: userRole) { success, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if success {
                    // Successfully joined family
                } else {
                    errorMessage = error?.localizedDescription ?? "Failed to join family"
                    showAlert = true
                }
            }
        }
    }
}

struct FamilySetupView_Previews: PreviewProvider {
    static var previews: some View {
        FamilySetupView()
            .environmentObject(SharedFamilyManager())
    }
}