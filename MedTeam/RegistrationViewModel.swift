//
//  File.swift
//  MedTeam
//
//  Created by Robert Plummer on 6/24/24.
//

import SwiftUI
import Foundation
import FirebaseAuth
import FirebaseCore


class RegistrationViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var fullname = ""
    @Published var username = ""
    @Published var credentials = ""
    
    @Published var errorMessage: String?
    @Published var isLoading = false

    @MainActor
    func createUser() async {
        let name = fullname.trimmingCharacters(in: .whitespaces)
        let handle = username.trimmingCharacters(in: .whitespaces)
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty, !handle.isEmpty else {
            errorMessage = "Please fill in email, password, full name, and username."
            return
        }
        guard name.split(separator: " ").count >= 2 else {
            errorMessage = "Please enter your first and last name."
            return
        }

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await AuthService.shared.createUser(
                withEmail: email.trimmingCharacters(in: .whitespaces),
                password: password,
                fullname: name,
                username: handle,
                credentials: credentials
            )
        } catch {
            errorMessage = AuthService.friendlyMessage(for: error)
        }
    }
}
