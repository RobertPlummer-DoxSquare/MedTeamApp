//
//  SafetyService.swift
//  MedTeam
//

import FirebaseFirestore
import FirebaseAuth

enum ReportReason: String, CaseIterable, Identifiable {
    case spam
    case harassment
    case inappropriate
    case impersonation
    case patientInfo
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .spam:          return "Spam or scam"
        case .harassment:    return "Harassment or hate"
        case .inappropriate: return "Inappropriate content"
        case .impersonation: return "Fake profile or impersonation"
        case .patientInfo:   return "Shared patient information"
        case .other:         return "Something else"
        }
    }
}

/// Reporting and blocking. Reports go to the `reports` collection for review;
/// blocked IDs live on the blocker's own user document.
class SafetyService {
    static let shared = SafetyService()
    private let db = Firestore.firestore()

    func report(userId: String, reason: ReportReason, details: String, conversationId: String? = nil) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var data: [String: Any] = [
            "reporterId": uid,
            "reportedUserId": userId,
            "reason": reason.rawValue,
            "details": details,
            "status": "open",
            "createdAt": Timestamp(date: Date())
        ]
        if let conversationId { data["conversationId"] = conversationId }
        try await db.collection("reports").addDocument(data: data)
    }

    /// Blocks a member: hides them everywhere for you, hides you from them in the
    /// directory, and closes any conversations between you.
    func block(userId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await UserService.shared.updateFields(["blockedUserIds": FieldValue.arrayUnion([userId])])

        let convos = try await db.collection("conversations")
            .whereField("participantIds", arrayContains: uid).getDocuments()
        for doc in convos.documents {
            let ids = doc.data()["participantIds"] as? [String] ?? []
            guard ids.contains(userId) else { continue }
            try await doc.reference.updateData(["status": ConversationStatus.archived.rawValue])
        }
    }

    func unblock(userId: String) async throws {
        try await UserService.shared.updateFields(["blockedUserIds": FieldValue.arrayRemove([userId])])
    }

    func isBlocked(_ userId: String) -> Bool {
        UserService.shared.currentUser?.blockedUserIds.contains(userId) ?? false
    }
}
