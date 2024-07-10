//
//  Settings.swift
//  MedTeamApp
//
//  Created by Robert Plummer on 7/4/24.
//

import SwiftUI

struct Settings: View {
    @State private var showingConfirmation = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack {
            Button(action: {
                showingConfirmation = true
            }) {
                Text("Delete Account")
                    .foregroundColor(.red)
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Account Deleted"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        // Handle logout action after account deletion
                        // For example, navigate to login screen or perform logout logic
                    }
                )
            }
        }
        .padding()
        .navigationBarTitle("Settings")
        .sheet(isPresented: $showingConfirmation) {
            ConfirmationView(confirmAction: deleteAccount)
        }
    }
    
    func deleteAccount() {
        // Simulate backend deletion and log out
        // Replace with actual backend interaction
        
        // Here, we simulate a deletion process
        // Assuming deletion is successful
        alertMessage = "Your account has been successfully deleted."
        showAlert = true
    }
}

struct ConfirmationView: View {
    let confirmAction: () -> Void
    
    var body: some View {
        VStack {
            Text("Are you sure you want to delete your account?")
                .padding()
            
            Button("Delete Account", action: {
                confirmAction()
            })
            .foregroundColor(.red)
            .padding()
        }
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings()
    }
}
