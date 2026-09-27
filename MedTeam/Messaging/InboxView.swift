import SwiftUI

struct InboxView: View {
    @ObservedObject var viewModel: InboxViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.nmaBackground.ignoresSafeArea()
                if !viewModel.hasLoaded {
                    ProgressView().tint(Color.nmaPrimary)
                } else if viewModel.conversations.isEmpty && viewModel.referralPings.isEmpty {
                    emptyState
                } else {
                    List {
                        if !viewModel.incomingRequests.isEmpty {
                            Section("Requests") {
                                ForEach(viewModel.incomingRequests) { convo in
                                    conversationLink(convo)
                                }
                            }
                        }
                        if !viewModel.otherConversations.isEmpty {
                            Section(viewModel.incomingRequests.isEmpty ? "" : "Conversations") {
                                ForEach(viewModel.otherConversations) { convo in
                                    conversationLink(convo)
                                }
                            }
                        }
                        if !viewModel.referralPings.isEmpty {
                            Section {
                                ForEach(viewModel.referralPings) { ping in
                                    ReferralHistoryRow(ping: ping, currentUserId: viewModel.currentUserId)
                                }
                            } header: {
                                Text("Past referral notifications")
                            } footer: {
                                Text("Referrals now happen by phone. Tap \"Call office for referrals\" on a member's profile.")
                            }
                            .onAppear { viewModel.markReferralsRead() }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func conversationLink(_ convo: Conversation) -> some View {
        NavigationLink(destination: ThreadView(conversation: convo)) {
            ConversationRowView(conversation: convo, currentUserId: viewModel.currentUserId)
        }
        .listRowBackground(Color.nmaSurface)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(Color.nmaSecondary)
            Text("No conversations yet")
                .font(.subheadline).fontWeight(.medium)
                .foregroundColor(Color.nmaPrimary)
            Text("Find someone in the Find tab and tap Connect.")
                .font(.caption)
                .foregroundColor(Color.nmaSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Conversation Row

struct ConversationRowView: View {
    let conversation: Conversation
    let currentUserId: String

    private var isUnread: Bool { conversation.isUnread(for: currentUserId) }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(conversation.type.color.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: conversation.type.iconSystemName)
                        .font(.system(size: 16))
                        .foregroundColor(conversation.type.color)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(conversation.otherParticipantName ?? "Unknown")
                        .font(.subheadline).fontWeight(isUnread ? .semibold : .medium)
                        .foregroundColor(Color.nmaPrimary)
                    Spacer()
                    if let date = conversation.lastMessageAt {
                        Text(date.timeAgoDisplay())
                            .font(.caption2).foregroundColor(Color.nmaSecondary)
                    }
                }
                HStack(spacing: 6) {
                    Text(conversation.type.displayName)
                        .font(.caption).foregroundColor(conversation.type.color)
                    RequestStatusBadge(conversation: conversation, currentUserId: currentUserId)
                }
                if let last = conversation.lastMessage {
                    Text(last)
                        .font(.caption)
                        .foregroundColor(isUnread ? Color.nmaPrimary : Color.nmaSecondary)
                        .lineLimit(1)
                }
            }

            if isUnread {
                Circle().fill(Color.regionBlue).frame(width: 8, height: 8)
                    .accessibilityLabel("Unread")
            }
        }
        .padding(.vertical, 4)
    }
}

/// "Pending" / "Accepted" / "Declined" label for request threads.
struct RequestStatusBadge: View {
    let conversation: Conversation
    let currentUserId: String

    var body: some View {
        if let (label, fg, bg) = info {
            Text(label)
                .font(.caption2).fontWeight(.medium)
                .foregroundColor(fg)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(bg).cornerRadius(4)
        }
    }

    private var info: (String, Color, Color)? {
        switch conversation.status {
        case .pending:
            return conversation.isRequester(currentUserId)
                ? ("Pending", .pendingAmber, .pendingAmberBackground)
                : ("New request", .regionBlue, .regionBlueBackground)
        case .declined:
            return ("Declined", .nmaSecondary, .nmaSubtle)
        case .active where conversation.requesterId != nil:
            return ("Accepted", .referralGreen, .referralGreenBackground)
        default:
            return nil
        }
    }
}

// MARK: - Referral History Row (read-only)

struct ReferralHistoryRow: View {
    let ping: Ping
    let currentUserId: String

    private var isReceived: Bool { ping.toUserId == currentUserId }
    private var otherUser: User? { isReceived ? ping.fromUser : ping.toUser }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(isReceived ? "Referral from" : "Referral to", systemImage: PingType.referral.iconSystemName)
                    .font(.caption).foregroundColor(.referralGreen)
                Spacer()
                Text(ping.createdAt.timeAgoDisplay())
                    .font(.caption2).foregroundColor(Color.nmaSecondary)
            }
            Text(otherUser?.fullname ?? "Unknown")
                .font(.subheadline).fontWeight(.medium).foregroundColor(Color.nmaPrimary)
            if isReceived, let phone = otherUser?.officePhone, !phone.isEmpty,
               let url = URL(string: "tel:\(phone.filter { $0.isNumber || $0 == "+" })") {
                Link(destination: url) {
                    Label(phone, systemImage: "phone")
                        .font(.caption).foregroundColor(.referralGreen)
                }
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.nmaSurface)
    }
}
