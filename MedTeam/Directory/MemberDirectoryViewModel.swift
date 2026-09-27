//
//  MemberDirectoryViewModel.swift
//  MedTeam
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

@MainActor
class MemberDirectoryViewModel: ObservableObject {
    @Published var users: [User] = []
    private let db = Firestore.firestore()

    init() {
        Task { await fetchUsers() }
    }

    func fetchUsers() async {
        do {
            let snapshot = try await db.collection("users").limit(to: 100).getDocuments()
            users = snapshot.documents.compactMap { try? $0.data(as: User.self) }
        } catch {
            print("MemberDirectoryViewModel fetch error: \(error)")
        }
    }
}
