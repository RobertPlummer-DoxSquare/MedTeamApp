import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

class MessagingService {
    static let shared = MessagingService()
    private let db = Firestore.firestore()

    func createConversation(from ping: Ping) async throws -> String {
        guard let pingId = ping.id else { throw MessagingError.missingPingId }

        var participantNames: [String: String] = [:]
        participantNames[ping.fromUserId] = ping.fromUser?.fullname ?? "Unknown"
        if let currentUser = UserService.shared.currentUser {
            participantNames[ping.toUserId] = currentUser.fullname
        }

        let ref = db.collection("conversations").document()
        let data: [String: Any] = [
            "pingId": pingId,
            "type": ping.type.rawValue,
            "participantIds": [ping.fromUserId, ping.toUserId],
            "status": ConversationStatus.active.rawValue,
            "createdAt": Timestamp(date: Date()),
            "lastMessage": "\(ping.type.displayName) thread opened",
            "lastMessageAt": Timestamp(date: Date()),
            "participantNames": participantNames
        ]
        try await ref.setData(data)

        let systemMsg: [String: Any] = [
            "senderId": "system",
            "text": "\(ping.type.displayName) thread opened",
            "type": Message.MessageType.system.rawValue,
            "createdAt": Timestamp(date: Date()),
            "readBy": [ping.toUserId]
        ]
        try await ref.collection("messages").addDocument(data: systemMsg)
        return ref.documentID
    }

    func fetchConversations(completion: @escaping ([Conversation]) -> Void) -> ListenerRegistration {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion([])
            return db.collection("conversations").addSnapshotListener { _, _ in }
        }
        return db.collection("conversations")
            .whereField("participantIds", arrayContains: uid)
            .order(by: "lastMessageAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                let convos: [Conversation] = snapshot?.documents.compactMap { doc in
                    guard var convo = try? doc.data(as: Conversation.self) else { return nil }
                    if let names = convo.participantNames {
                        let otherUid = convo.participantIds.first { $0 != uid } ?? ""
                        convo.otherParticipantName = names[otherUid]
                    }
                    return convo
                } ?? []
                DispatchQueue.main.async { completion(convos) }
            }
    }

    func fetchMessages(conversationId: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration {
        return db.collection("conversations").document(conversationId)
            .collection("messages")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, _ in
                let messages = snapshot?.documents.compactMap {
                    try? $0.data(as: Message.self)
                } ?? []
                DispatchQueue.main.async { completion(messages) }
            }
    }

    func sendMessage(conversationId: String, text: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let msgData: [String: Any] = [
            "senderId": uid,
            "text": text,
            "type": Message.MessageType.text.rawValue,
            "createdAt": Timestamp(date: Date()),
            "readBy": [uid]
        ]
        try await db.collection("conversations").document(conversationId)
            .collection("messages").addDocument(data: msgData)
        try await db.collection("conversations").document(conversationId).updateData([
            "lastMessage": text,
            "lastMessageAt": Timestamp(date: Date())
        ])
    }

    func submitReferralCard(_ card: ReferralCard, conversationId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var dict: [String: Any] = ["isConfirmed": false]
        if let age    = card.patientAge         { dict["patientAge"] = age }
        if let dx     = card.diagnosis          { dict["diagnosis"] = dx }
        if let reason = card.reasonForReferral  { dict["reasonForReferral"] = reason }
        if let urg    = card.urgency            { dict["urgency"] = urg.rawValue }
        if let ins    = card.insurance          { dict["insurance"] = ins }

        try await db.collection("conversations").document(conversationId).updateData([
            "referralCard": dict,
            "lastMessage": "Referral details submitted",
            "lastMessageAt": Timestamp(date: Date())
        ])
        let msgData: [String: Any] = [
            "senderId": uid,
            "text": "Referral details submitted",
            "type": Message.MessageType.referralCard.rawValue,
            "createdAt": Timestamp(date: Date()),
            "readBy": [uid]
        ]
        try await db.collection("conversations").document(conversationId)
            .collection("messages").addDocument(data: msgData)
    }

    func submitProposalCard(_ card: ProposalCard, conversationId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var dict: [String: Any] = ["isSubmitted": true]
        if let topic    = card.topic       { dict["topic"] = topic }
        if let stage    = card.stage       { dict["stage"] = stage.rawValue }
        if let role     = card.roleNeeded  { dict["roleNeeded"] = role }
        if let timeline = card.timeline    { dict["timeline"] = timeline }

        try await db.collection("conversations").document(conversationId).updateData([
            "proposalCard": dict,
            "lastMessage": "Research proposal submitted",
            "lastMessageAt": Timestamp(date: Date())
        ])
        let msgData: [String: Any] = [
            "senderId": uid,
            "text": "Research proposal submitted",
            "type": Message.MessageType.proposalCard.rawValue,
            "createdAt": Timestamp(date: Date()),
            "readBy": [uid]
        ]
        try await db.collection("conversations").document(conversationId)
            .collection("messages").addDocument(data: msgData)
    }

    func confirmReferral(conversationId: String) async throws {
        try await db.collection("conversations").document(conversationId).updateData([
            "referralCard.isConfirmed": true
        ])
    }
}

enum MessagingError: Error {
    case missingPingId
}
