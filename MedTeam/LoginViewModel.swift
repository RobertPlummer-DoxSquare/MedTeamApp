//
//  LoginViewModel.swift
//  MedTeam
//
//  Created by Robert Plummer on 6/24/24.
//

import Foundation
import FirebaseAuth

class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var loginError: String?
    
    var isAuthenticated: Bool {
        return Auth.auth().currentUser != nil
    }

    func login() async {
        do {
            try await AuthService.shared.login(withEmail: email, password: password)
            print("User signed in")
            loginError = nil
        } catch {
            loginError = error.localizedDescription
            print("Login error: \(error.localizedDescription)")
        }
    }
}
