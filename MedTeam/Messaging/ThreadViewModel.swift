import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ThreadViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var messageText = ""
    @Published var isSending = false
    @Published var isResponding = false
    @Published var conversation: Conversation

    private var messageListener: ListenerRegistration?
    private var conversationListener: ListenerRegistration?

    init(conversation: Conversation) {
        self.conversation = conversation
    }

    var currentUserId: String { Auth.auth().currentUser?.uid ?? "" }

    var isRequester: Bool { conversation.isRequester(currentUserId) }

    var otherParticipantId: String? { conversation.otherParticipantId(for: currentUserId) }

    /// Receiver of a pending request sees Accept / Decline.
    var canRespond: Bool { conversation.status == .pending && !isRequester }

    var canMessage: Bool { conversation.status == .active }

    var needsProposalCard: Bool {
        conversation.type == .collaboration &&
        conversation.status == .active &&
        conversation.proposalCard == nil &&
        isRequester
    }

    var canConfirmReferral: Bool {
        conversation.type == .referral &&
        conversation.referralCard != nil &&
        !(conversation.referralCard?.isConfirmed ?? false) &&
        !isRequester
    }

    func startListening() {
        guard let id = conversation.id else { return }
        messageListener = MessagingService.shared.fetchMessages(conversationId: id) { [weak self] msgs in
            self?.messages = msgs
            self?.markRead()
        }
        conversationListener = MessagingService.shared.listenToConversation(id: id) { [weak self] convo in
            self?.conversation = convo
        }
    }

    func stopListening() {
        messageListener?.remove()
        conversationListener?.remove()
    }

    func markRead() {
        guard let id = conversation.id, conversation.isUnread(for: currentUserId) else { return }
        Task { try? await MessagingService.shared.markRead(conversationId: id) }
    }

    func send() async {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, canMessage, let id = conversation.id else { return }
        messageText = ""
        isSending = true
        try? await MessagingService.shared.sendMessage(conversationId: id, text: text)
        isSending = false
    }

    func respond(accept: Bool) async {
        guard let id = conversation.id else { return }
        isResponding = true
        defer { isResponding = false }
        try? await MessagingService.shared.respondToRequest(conversationId: id, accept: accept)
    }

    func submitProposalCard(_ card: ProposalCard) async {
        guard let id = conversation.id else { return }
        try? await MessagingService.shared.submitProposalCard(card, conversationId: id)
    }

    func confirmReferral() async {
        guard let id = conversation.id else { return }
        try? await MessagingService.shared.confirmReferral(conversationId: id)
    }
}
