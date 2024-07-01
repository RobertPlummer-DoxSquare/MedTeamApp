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
    @Published var credentials = "MD, RN, PA, Student"
    
 @MainActor
    func createUser() async throws {
       try await AuthService.shared.createUser(
            withEmail: email,
            password: password,
            fullname: fullname,
            username: username,
            credentials: credentials
       )
    }
}
