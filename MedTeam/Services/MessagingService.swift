import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

class MessagingService {
    static let shared = MessagingService()
    private let db = Firestore.firestore()

    /// Sends a mentorship or collaboration request as a pending conversation.
    func sendRequest(to target: User, type: PingType, note: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let myName = UserService.shared.currentUser?.fullname ?? "Unknown"
        let now = Timestamp(date: Date())
        let summary = "\(type.displayName) request"

        let ref = db.collection("conversations").document()
        try await ref.setData([
            "type": type.rawValue,
            "requesterId": uid,
            "participantIds": [uid, target.id],
            "participantNames": [uid: myName, target.id: target.fullname],
            "status": ConversationStatus.pending.rawValue,
            "createdAt": now,
            "lastMessage": note.isEmpty ? summary : note,
            "lastMessageAt": now,
            "lastMessageSenderId": uid,
            "lastReadAt": [uid: now]
        ])
        try await ref.collection("messages").addDocument(data: [
            "senderId": "system",
            "text": "\(myName) sent a \(type.displayName.lowercased()) request",
            "type": Message.MessageType.system.rawValue,
            "createdAt": now,
            "readBy": [uid]
        ])
        if !note.isEmpty {
            try await ref.collection("messages").addDocument(data: [
                "senderId": uid,
                "text": note,
                "type": Message.MessageType.text.rawValue,
                "createdAt": Timestamp(date: Date()),
                "readBy": [uid]
            ])
        }
    }

    /// Receiver accepts or declines a pending request.
    func respondToRequest(conversationId: String, accept: Bool) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let text = accept ? "Request accepted" : "Request declined"
        let now = Timestamp(date: Date())
        let ref = db.collection("conversations").document(conversationId)
        try await ref.updateData([
            "status": (accept ? ConversationStatus.active : .declined).rawValue,
            "lastMessage": text,
            "lastMessageAt": now,
            "lastMessageSenderId": uid,
            "lastReadAt.\(uid)": now
        ])
        try await ref.collection("messages").addDocument(data: [
            "senderId": "system",
            "text": text,
            "type": Message.MessageType.system.rawValue,
            "createdAt": now,
            "readBy": [uid]
        ])
    }

    func markRead(conversationId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await db.collection("conversations").document(conversationId)
            .updateData(["lastReadAt.\(uid)": Timestamp(date: Date())])
    }

    func listenToConversation(id: String, completion: @escaping (Conversation) -> Void) -> ListenerRegistration {
        let uid = Auth.auth().currentUser?.uid ?? ""
        return db.collection("conversations").document(id).addSnapshotListener { snapshot, _ in
            guard var convo = try? snapshot?.data(as: Conversation.self) else { return }
            if let other = convo.otherParticipantId(for: uid) {
                convo.otherParticipantName = convo.participantNames?[other]
            }
            DispatchQueue.main.async { completion(convo) }
        }
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
        let now = Timestamp(date: Date())
        try await db.collection("conversations").document(conversationId).updateData([
            "lastMessage": text,
            "lastMessageAt": now,
            "lastMessageSenderId": uid,
            "lastReadAt.\(uid)": now
        ])
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

