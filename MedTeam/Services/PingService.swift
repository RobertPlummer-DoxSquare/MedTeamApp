//
//  PingService.swift
//  MedTeam
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

class PingService {
    static let shared = PingService()
    private let db = Firestore.firestore()

    func sendPing(to toUserId: String, type: PingType, note: String?) async throws {
        guard let fromUserId = Auth.auth().currentUser?.uid else { return }
        let ping = Ping(
            fromUserId: fromUserId,
            toUserId: toUserId,
            type: type,
            note: note?.isEmpty == true ? nil : note,
            status: .pending,
            createdAt: Date()
        )
        try db.collection("pings").addDocument(from: ping)
    }

    func fetchReceivedPings(completion: @escaping ([Ping]) -> Void) -> ListenerRegistration {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion([])
            return db.collection("pings").addSnapshotListener { _, _ in }
        }
        return db.collection("pings")
            .whereField("toUserId", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                let pings = snapshot?.documents.compactMap { try? $0.data(as: Ping.self) } ?? []
                Task {
                    let attached = await self.attachUsers(to: pings, idKeyPath: \.fromUserId)
                    DispatchQueue.main.async { completion(attached) }
                }
            }
    }

    func fetchSentPings(completion: @escaping ([Ping]) -> Void) -> ListenerRegistration {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion([])
            return db.collection("pings").addSnapshotListener { _, _ in }
        }
        return db.collection("pings")
            .whereField("fromUserId", isEqualTo: uid)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                let pings = snapshot?.documents.compactMap { try? $0.data(as: Ping.self) } ?? []
                Task {
                    let attached = await self.attachUsers(to: pings, idKeyPath: \.toUserId, writing: \.toUser)
                    DispatchQueue.main.async { completion(attached) }
                }
            }
    }

    func updateStatus(_ pingId: String, status: PingStatus) async throws {
        try await db.collection("pings").document(pingId).updateData([
            "status": status.rawValue
        ])
    }

    func markRead(_ pingId: String) async throws {
        try await db.collection("pings").document(pingId).updateData([
            "readAt": Timestamp(date: Date())
        ])
    }

    func unreadCount(from pings: [Ping]) -> Int {
        pings.filter { $0.status == .pending && $0.readAt == nil }.count
    }

    private func attachUsers(to pings: [Ping], idKeyPath: KeyPath<Ping, String>, writing: WritableKeyPath<Ping, User?> = \.fromUser) async -> [Ping] {
        let uniqueIds = Array(Set(pings.map { $0[keyPath: idKeyPath] }))
        var userMap: [String: User] = [:]
        await withTaskGroup(of: (String, User?).self) { group in
            for uid in uniqueIds {
                group.addTask {
                    let user = try? await UserService.fetchUser(withUid: uid)
                    return (uid, user)
                }
            }
            for await (uid, user) in group {
                if let user { userMap[uid] = user }
            }
        }
        var result = pings
        for i in result.indices {
            result[i][keyPath: writing] = userMap[result[i][keyPath: idKeyPath]]
        }
        return result
    }
}
