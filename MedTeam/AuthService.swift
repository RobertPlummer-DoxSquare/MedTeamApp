//
//  AuthService.swift
//  MedTeam
//
//  Created by Robert Plummer on 6/24/24.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

class AuthService: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    
    static let shared = AuthService()
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        self.userSession = Auth.auth().currentUser
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.userSession = user
            if let user = user {
                Task {
                    try await UserService.shared.fetchCurrentUser()
                }
            }
        }
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    @MainActor
    func login(withEmail email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            try await UserService.shared.fetchCurrentUser()
        } catch {
//            print("Debug: Failed to log in - \(error.localizedDescription)")
            throw error
        }
    }
    
    @MainActor
    func createUser(withEmail email: String, password: String, fullname: String, username: String, credentials: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            try await uploadUserData(withEmail: email, fullname: fullname, username: username, credentials: credentials, id: result.user.uid)
        } catch {
            print("Debug: Failed to create user - \(error.localizedDescription)")
            throw error
        }
    }
    
    func signOut() {
        do {
            try? Auth.auth().signOut()
            self.userSession = nil
            UserService.shared.reset()
        } catch {
            print("Debug: Failed to sign out - \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func uploadUserData(withEmail email: String, fullname: String, username: String, credentials: String, id: String) async throws {
        let user = User(id: id, email: email, fullname: fullname, username: username, credentials: credentials)
        do {
            let userData = try Firestore.Encoder().encode(user)
            try await Firestore.firestore().collection("users").document(id).setData(userData)
            UserService.shared.currentUser = user
        } catch {
            print("Debug: Failed to upload user data - \(error.localizedDescription)")
            throw error
        }
    }
    
}

