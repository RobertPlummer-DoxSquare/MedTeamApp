//
//  LoginViewModel.swift
//  MedTeam
//
//  Created by Robert Plummer on 6/24/24.
//

import Foundation
import FirebaseAuth

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var loginError: String?
    @Published var isLoading = false

    // Password reset
    @Published var resetEmail = ""
    @Published var resetResultMessage: String?

    var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty && !isLoading
    }

    func login() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AuthService.shared.login(
                withEmail: email.trimmingCharacters(in: .whitespaces),
                password: password
            )
            loginError = nil
        } catch {
            loginError = AuthService.friendlyMessage(for: error)
        }
    }

    func sendPasswordReset() async {
        let address = resetEmail.trimmingCharacters(in: .whitespaces)
        do {
            try await AuthService.shared.sendPasswordReset(toEmail: address)
            resetResultMessage = "If an account exists for \(address), a password reset link is on its way. Check your inbox."
        } catch {
            resetResultMessage = AuthService.friendlyMessage(for: error)
        }
    }
}
