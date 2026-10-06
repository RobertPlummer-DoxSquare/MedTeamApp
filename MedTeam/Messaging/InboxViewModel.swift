import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

/// Single source for the Inbox tab: conversations (including requests) plus
/// legacy referral notifications, which are read-only.
@MainActor
class InboxViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var referralPings: [Ping] = []
    @Published var hasLoaded = false

    private var conversationListener: ListenerRegistration?
    private var receivedListener: ListenerRegistration?
    private var sentListener: ListenerRegistration?
    private var receivedReferrals: [Ping] = []
    private var sentReferrals: [Ping] = []
    private var allConversations: [Conversation] = []
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Re-filter when the block list changes.
        UserService.shared.$currentUser
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.applyBlockFilter() }
            .store(in: &cancellables)
    }

    var currentUserId: String { Auth.auth().currentUser?.uid ?? "" }

    /// Requests waiting for this user to accept or decline.
    var incomingRequests: [Conversation] {
        conversations.filter { $0.status == .pending && !$0.isRequester(currentUserId) }
    }

    var otherConversations: [Conversation] {
        conversations.filter { !($0.status == .pending && !$0.isRequester(currentUserId)) }
    }

    var unreadCount: Int {
        conversations.filter { $0.isUnread(for: currentUserId) }.count
            + receivedReferrals.filter { $0.readAt == nil }.count
    }

    func startListening() {
        guard conversationListener == nil else { return }
        conversationListener = MessagingService.shared.fetchConversations { [weak self] convos in
            self?.allConversations = convos
            self?.applyBlockFilter()
            self?.hasLoaded = true
        }
        receivedListener = PingService.shared.fetchReceivedPings { [weak self] pings in
            Task { @MainActor in
                self?.receivedReferrals = pings.filter { $0.type == .referral }
                self?.mergeReferrals()
            }
        }
        sentListener = PingService.shared.fetchSentPings { [weak self] pings in
            Task { @MainActor in
                self?.sentReferrals = pings.filter { $0.type == .referral }
                self?.mergeReferrals()
            }
        }
    }

    func stopListening() {
        conversationListener?.remove()
        receivedListener?.remove()
        sentListener?.remove()
        conversationListener = nil
    }

    /// Called when the referral history is on screen.
    func markReferralsRead() {
        for ping in receivedReferrals where ping.readAt == nil {
            guard let id = ping.id else { continue }
            Task { try? await PingService.shared.markRead(id) }
        }
    }

    private func applyBlockFilter() {
        let blocked = Set(UserService.shared.currentUser?.blockedUserIds ?? [])
        conversations = allConversations.filter { convo in
            guard let other = convo.otherParticipantId(for: currentUserId) else { return true }
            return !blocked.contains(other)
        }
    }

    private func mergeReferrals() {
        referralPings = (receivedReferrals + sentReferrals).sorted { $0.createdAt > $1.createdAt }
    }
}
