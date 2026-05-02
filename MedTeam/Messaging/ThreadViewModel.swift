import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ThreadViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var messageText = ""
    @Published var isSending = false
    @Published var conversation: Conversation

    private var listener: ListenerRegistration?

    init(conversation: Conversation) {
        self.conversation = conversation
    }

    var currentUserId: String { Auth.auth().currentUser?.uid ?? "" }

    var isInitiator: Bool {
        conversation.participantIds.first == currentUserId
    }

    var needsReferralCard: Bool {
        conversation.type == .referral &&
        conversation.referralCard == nil &&
        isInitiator
    }

    var needsProposalCard: Bool {
        conversation.type == .collaboration &&
        conversation.proposalCard == nil &&
        isInitiator
    }

    var canConfirmReferral: Bool {
        conversation.type == .referral &&
        conversation.referralCard != nil &&
        !(conversation.referralCard?.isConfirmed ?? false) &&
        !isInitiator
    }

    func startListening() {
        guard let id = conversation.id else { return }
        listener = MessagingService.shared.fetchMessages(conversationId: id) { [weak self] msgs in
            self?.messages = msgs
        }
    }

    func stopListening() { listener?.remove() }

    func send() async {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let id = conversation.id else { return }
        messageText = ""
        isSending = true
        try? await MessagingService.shared.sendMessage(conversationId: id, text: text)
        isSending = false
    }

    func submitReferralCard(_ card: ReferralCard) async {
        guard let id = conversation.id else { return }
        try? await MessagingService.shared.submitReferralCard(card, conversationId: id)
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
