import SwiftUI

struct ConversationListView: View {
    @ObservedObject var viewModel: ConversationListViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
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
                                        .background(Color(white: 0.1))
                                        .padding(.leading, 72)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
            .colorScheme(.dark)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "message")
                .font(.system(size: 40))
                .foregroundColor(Color(white: 0.25))
            Text("No messages yet")
                .font(.subheadline).fontWeight(.medium)
                .foregroundColor(Color(white: 0.45))
            Text("Accept a ping to start a conversation.")
                .font(.caption)
                .foregroundColor(Color(white: 0.3))
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
                .fill(conversation.type.accentColor.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: conversation.type.iconSystemName)
                        .font(.system(size: 16))
                        .foregroundColor(conversation.type.accentColor)
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(conversation.otherParticipantName ?? "Unknown")
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundColor(.white)
                    Spacer()
                    if let date = conversation.lastMessageAt {
                        Text(date.timeAgoDisplay())
                            .font(.caption2)
                            .foregroundColor(Color(white: 0.4))
                    }
                }
                Text(conversation.type.displayName)
                    .font(.caption)
                    .foregroundColor(conversation.type.accentColor)
                if let last = conversation.lastMessage {
                    Text(last)
                        .font(.caption)
                        .foregroundColor(Color(white: 0.45))
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}
