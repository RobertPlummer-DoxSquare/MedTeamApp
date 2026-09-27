import SwiftUI

struct ConversationListView: View {
    @ObservedObject var viewModel: ConversationListViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.nmaBackground.ignoresSafeArea()
                Group {
                    if viewModel.conversations.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(viewModel.conversations) { convo in
                                    NavigationLink(destination: ThreadView(conversation: convo)) {
                                        ConversationRowView(conversation: convo)
                                    }
                                    .buttonStyle(.plain)
                                    Divider()
                                        .background(Color.nmaBorder)
                                        .padding(.leading, 72)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "message")
                .font(.system(size: 40))
                .foregroundColor(Color.nmaSecondary)
            Text("No messages yet")
                .font(.subheadline).fontWeight(.medium)
                .foregroundColor(Color.nmaSecondary)
            Text("Send a message to start a conversation.")
                .font(.caption)
                .foregroundColor(Color.nmaSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ConversationRowView: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(typeColor.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: conversation.type.iconSystemName)
                        .font(.system(size: 16))
                        .foregroundColor(typeColor)
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(conversation.otherParticipantName ?? "Unknown")
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundColor(Color.nmaPrimary)
                    Spacer()
                    if let date = conversation.lastMessageAt {
                        Text(date.timeAgoDisplay())
                            .font(.caption2).foregroundColor(Color.nmaSecondary)
                    }
                }
                Text(conversation.type.displayName)
                    .font(.caption).foregroundColor(typeColor)
                if let last = conversation.lastMessage {
                    Text(last).font(.caption).foregroundColor(Color.nmaSecondary).lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .background(Color.nmaBackground)
    }

    private var typeColor: Color {
        switch conversation.type {
        case .referral:      return .green
        case .mentorship:    return .blue
        case .collaboration: return Color(hex: "3C2D8A")
        }
    }
}
