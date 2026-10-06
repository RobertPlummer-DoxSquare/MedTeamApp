import SwiftUI

struct ThreadView: View {
    @StateObject private var viewModel: ThreadViewModel
    @State private var showProposalForm = false
    @Environment(\.dismiss) private var dismiss
    @FocusState private var inputFocused: Bool

    init(conversation: Conversation) {
        _viewModel = StateObject(wrappedValue: ThreadViewModel(conversation: conversation))
    }

    var body: some View {
        ZStack {
            Color.nmaBackground.ignoresSafeArea()
            VStack(spacing: 0) {

                privacyNote

                if viewModel.needsProposalCard {
                    actionBanner(
                        icon: "testtube.2",
                        color: PingType.collaboration.color,
                        text: "Describe your research proposal.",
                        buttonLabel: "Add details"
                    ) { showProposalForm = true }
                }

                if let card = viewModel.conversation.referralCard {
                    ReferralCardView(
                        card: card,
                        canConfirm: viewModel.canConfirmReferral,
                        onConfirm: { Task { await viewModel.confirmReferral() } }
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    Divider().background(Color.nmaBorder)
                } else if let card = viewModel.conversation.proposalCard {
                    ProposalCardView(card: card)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    Divider().background(Color.nmaBorder)
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(
                                    message: message,
                                    isOwn: message.senderId == viewModel.currentUserId
                                )
                                .id(message.id)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        if let last = viewModel.messages.last?.id {
                            withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                        }
                    }
                    .onAppear {
                        if let last = viewModel.messages.last?.id {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }

                footer
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text(viewModel.conversation.otherParticipantName ?? "Thread")
                        .font(.subheadline).fontWeight(.semibold).foregroundColor(.nmaPrimary)
                    Text(viewModel.conversation.type.displayName)
                        .font(.caption2)
                        .foregroundColor(viewModel.conversation.type.accentColor)
                }
            }
            if let otherId = viewModel.otherParticipantId {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SafetyMenu(
                        userId: otherId,
                        userName: viewModel.conversation.otherParticipantName ?? "this member",
                        conversationId: viewModel.conversation.id
                    ) { dismiss() }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.startListening() }
        .onDisappear { viewModel.stopListening() }
        .sheet(isPresented: $showProposalForm) {
            ProposalCardFormView { card in
                Task { await viewModel.submitProposalCard(card) }
            }
        }
    }

    private var privacyNote: some View {
        Label("Don't share patient information here.", systemImage: "lock.fill")
            .font(.caption2)
            .foregroundColor(.nmaSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color.nmaSubtle)
    }

    @ViewBuilder
    private var footer: some View {
        if viewModel.canRespond {
            requestResponseBar
        } else if viewModel.canMessage {
            inputBar
        } else {
            statusBar
        }
    }

    private var requestResponseBar: some View {
        VStack(spacing: 10) {
            Text("\(viewModel.conversation.otherParticipantName ?? "This member") sent you a \(viewModel.conversation.type.displayName.lowercased()) request.")
                .font(.footnote).foregroundColor(.nmaSecondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 12) {
                Button {
                    Task { await viewModel.respond(accept: false) }
                } label: {
                    Text("Decline")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .foregroundColor(.nmaPrimary)
                        .background(Color.nmaSubtle)
                        .cornerRadius(10)
                }
                Button {
                    Task { await viewModel.respond(accept: true) }
                } label: {
                    Text("Accept")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .foregroundColor(.white)
                        .background(Color.nmaPrimary)
                        .cornerRadius(10)
                }
            }
            .disabled(viewModel.isResponding)
        }
        .padding(12)
        .background(Color.nmaSurface)
        .overlay(alignment: .top) { Divider().background(Color.nmaBorder) }
    }

    private var statusBar: some View {
        let text: String
        switch viewModel.conversation.status {
        case .pending:
            text = "Waiting for \(viewModel.conversation.otherParticipantName ?? "them") to accept your request."
        case .declined:
            text = viewModel.isRequester ? "Your request was declined." : "You declined this request."
        default:
            text = "This conversation is closed."
        }
        return Text(text)
            .font(.footnote).foregroundColor(.nmaSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color.nmaSurface)
            .overlay(alignment: .top) { Divider().background(Color.nmaBorder) }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Message...", text: $viewModel.messageText, axis: .vertical)
                .lineLimit(1...4)
                .foregroundColor(.nmaPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.nmaSubtle)
                .cornerRadius(20)
                .focused($inputFocused)
            Button {
                Task { await viewModel.send() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(
                        viewModel.messageText.trimmingCharacters(in: .whitespaces).isEmpty
                        ? Color.nmaBorder : Color.nmaPrimary
                    )
            }
            .disabled(
                viewModel.messageText.trimmingCharacters(in: .whitespaces).isEmpty ||
                viewModel.isSending
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.nmaSurface)
        .overlay(alignment: .top) { Divider().background(Color.nmaBorder) }
    }

    @ViewBuilder
    private func actionBanner(
        icon: String, color: Color, text: String,
        buttonLabel: String, action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12))
                .cornerRadius(8)
            Text(text)
                .font(.caption)
                .foregroundColor(.nmaSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button(action: action) {
                Text(buttonLabel)
                    .font(.caption).fontWeight(.semibold)
                    .foregroundColor(color)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(color.opacity(0.12))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.nmaSurface)
    }
}

struct MessageBubble: View {
    let message: Message
    let isOwn: Bool

    var body: some View {
        if message.type == .system {
            Text(message.text)
                .font(.caption2)
                .foregroundColor(.nmaSecondary)
                .italic()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        } else {
            HStack {
                if isOwn { Spacer(minLength: 60) }
                Text(message.text)
                    .font(.subheadline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(isOwn ? Color.nmaPrimary : Color.nmaSurface)
                    .foregroundColor(isOwn ? .white : .nmaPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isOwn ? Color.clear : Color.nmaBorder, lineWidth: 0.5)
                    )
                    .cornerRadius(18)
                    .cornerRadius(isOwn ? 4 : 18, corners: isOwn ? .bottomRight : .bottomLeft)
                if !isOwn { Spacer(minLength: 60) }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 2)
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
