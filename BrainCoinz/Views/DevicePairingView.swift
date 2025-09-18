//
//  DevicePairingView.swift
//  BrainCoinz
//
//  Device pairing interface for adding child devices to family account
//  Simplifies the process of connecting multiple family devices
//

import SwiftUI

/**
 * Device pairing view that helps parents add child devices to their family account.
 * Provides QR code generation and family code sharing for easy device registration.
 */
struct DevicePairingView: View {
    @EnvironmentObject var familyAccountManager: FamilyAccountManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var familyCode = ""
    @State private var showingQRCode = false
    @State private var isGeneratingCode = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Add Child Device")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Connect a child's device to your family account for remote control")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Family code section
                VStack(spacing: 20) {
                    if let family = familyAccountManager.familyAccount {
                        VStack(spacing: 16) {
                            Text("Family Code")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(family.familyCode)
                                .font(.system(size: 36, weight: .bold, design: .monospaced))
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            
                            Text("Share this code with your child's device to connect it to your family account")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            Button("Share Family Code") {
                                shareCode(family.familyCode)
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                            
                            Button("Show QR Code") {
                                showingQRCode = true
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                    } else {
                        // No family account
                        VStack(spacing: 16) {
                            Text("No Family Account")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("You need to create a family account first before adding devices")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Create Family Account") {
                                dismiss()
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    }
                }
                
                Spacer()
                
                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Instructions:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    InstructionStep(
                        number: "1",
                        text: "Install BrainCoinz on your child's device"
                    )
                    
                    InstructionStep(
                        number: "2", 
                        text: "Open the app and choose 'Join Family'"
                    )
                    
                    InstructionStep(
                        number: "3",
                        text: "Enter the family code or scan the QR code"
                    )
                    
                    InstructionStep(
                        number: "4",
                        text: "Complete setup and start remote control"
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
            .navigationTitle("Device Pairing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingQRCode) {
            if let family = familyAccountManager.familyAccount {
                QRCodeView(familyCode: family.familyCode)
            }
        }
    }
    
    /**
     * Shares the family code using the system share sheet
     */
    private func shareCode(_ code: String) {
        let activityVC = UIActivityViewController(
            activityItems: [
                "Join our BrainCoinz family with code: \(code)\n\nDownload BrainCoinz and use this code to connect your device for remote screen time management."
            ],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

/**
 * Instruction step component
 */
struct InstructionStep: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue)
                .frame(width: 24, height: 24)
                .overlay(
                    Text(number)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

/**
 * QR Code display view
 */
struct QRCodeView: View {
    let familyCode: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Scan QR Code")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // QR Code placeholder - in real implementation, would generate actual QR code
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 200, height: 200)
                    .cornerRadius(12)
                    .overlay(
                        VStack {
                            Image(systemName: "qrcode")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                            
                            Text("QR CODE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    )
                
                Text("Family Code: \(familyCode)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Scan this QR code with the child's device or manually enter the family code")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .navigationTitle("QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DevicePairingView()
        .environmentObject(FamilyAccountManager())
}