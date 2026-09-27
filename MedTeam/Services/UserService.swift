//
//  UserService.swift
//  MedTeam
//
//  Created by Robert Plummer on 6/25/24.
//

import Firebase
import FirebaseFirestoreSwift
import Combine

class UserService: ObservableObject {
    @Published var currentUser: User?

    static let shared = UserService()

    init() {
        Task { try? await fetchCurrentUser() }
    }

    @MainActor
    func fetchCurrentUser() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
        self.currentUser = try snapshot.data(as: User.self)
    }

    static func fetchUsers() async throws -> [User] {
        guard let currentUid = Auth.auth().currentUser?.uid else { return [] }
        let snapshot = try await Firestore.firestore().collection("users").getDocuments()
        return snapshot.documents
            .compactMap { try? $0.data(as: User.self) }
            .filter { $0.id != currentUid }
    }

    static func fetchUser(withUid uid: String) async throws -> User {
        let snapshot = try await Firestore.firestore().collection("users").document(uid).getDocument()
        return try snapshot.data(as: User.self)
    }

    /// Writes fields to the signed-in user's document, then refreshes currentUser.
    func updateFields(_ fields: [String: Any]) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await Firestore.firestore().collection("users").document(uid).updateData(fields)
        try await fetchCurrentUser()
    }

    func reset() {
        self.currentUser = nil
    }
}
