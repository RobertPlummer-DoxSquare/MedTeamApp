//
//  SafetyViews.swift
//  MedTeam
//

import SwiftUI

enum AppLinks {
    static let privacyPolicy = URL(string: "https://robertplummer-doxsquare.github.io/MedTeamApp/privacy.html")!
}

// MARK: - Report / Block Menu

/// Toolbar "..." menu with Report and Block for another member.
struct SafetyMenu: View {
    let userId: String
    let userName: String
    var conversationId: String? = nil
    /// Called after a successful block, e.g. to leave the screen.
    var onBlocked: () -> Void = {}

    @ObservedObject private var userService = UserService.shared
    @State private var showReport = false
    @State private var showBlockConfirm = false

    private var isBlocked: Bool { userService.currentUser?.blockedUserIds.contains(userId) ?? false }

    var body: some View {
        Menu {
            Button { showReport = true } label: {
                Label("Report \(userName)", systemImage: "flag")
            }
            if isBlocked {
                Button {
                    Task { try? await SafetyService.shared.unblock(userId: userId) }
                } label: {
                    Label("Unblock", systemImage: "hand.raised.slash")
                }
            } else {
                Button(role: .destructive) { showBlockConfirm = true } label: {
                    Label("Block", systemImage: "hand.raised")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundColor(.nmaPrimary)
        }
        .sheet(isPresented: $showReport) {
            ReportUserView(userId: userId, userName: userName, conversationId: conversationId)
        }
        .confirmationDialog("Block \(userName)?", isPresented: $showBlockConfirm, titleVisibility: .visible) {
            Button("Block", role: .destructive) {
                Task {
                    try? await SafetyService.shared.block(userId: userId)
                    onBlocked()
                }
            }
        } message: {
            Text("They won't be able to find you or message you, and your conversations with them will close. They won't be notified.")
        }
    }
}

// MARK: - Report Sheet

struct ReportUserView: View {
    let userId: String
    let userName: String
    var conversationId: String? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var reason: ReportReason?
    @State private var details = ""
    @State private var alsoBlock = false
    @State private var isSubmitting = false
    @State private var submitted = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if submitted {
                    confirmation
                } else {
                    form
                }
            }
            .background(Color.nmaBackground)
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(submitted ? "Done" : "Cancel") { dismiss() }
                        .foregroundColor(.nmaPrimary)
                }
            }
        }
    }

    private var form: some View {
        List {
            Section {
                ForEach(ReportReason.allCases) { r in
                    Button { reason = r } label: {
                        HStack {
                            Text(r.displayName).foregroundColor(.nmaPrimary)
                            Spacer()
                            if reason == r {
                                Image(systemName: "checkmark").foregroundColor(.nmaPrimary)
                            }
                        }
                    }
                }
            } header: {
                Text("Why are you reporting \(userName)?")
            }

            Section("Details (optional)") {
                TextField("What happened?", text: $details, axis: .vertical)
                    .lineLimit(3...6)
                    .foregroundColor(.nmaPrimary)
            }

            Section {
                Toggle("Also block \(userName)", isOn: $alsoBlock)
                    .tint(Color.nmaPrimary)
            } footer: {
                if let errorMessage {
                    Text(errorMessage).foregroundColor(.red)
                } else {
                    Text("Reports are confidential. Our team reviews every report within 24 hours and removes content or members that break the rules.")
                }
            }

            Section {
                Button {
                    submit()
                } label: {
                    HStack {
                        Spacer()
                        if isSubmitting { ProgressView() } else { Text("Submit Report").fontWeight(.semibold) }
                        Spacer()
                    }
                }
                .disabled(reason == nil || isSubmitting)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var confirmation: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 44))
                .foregroundColor(.referralGreen)
            Text("Thanks for letting us know")
                .font(.headline).foregroundColor(.nmaPrimary)
            Text(alsoBlock ? "We'll review your report. \(userName) has been blocked." : "We'll review your report.")
                .font(.subheadline).foregroundColor(.nmaSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func submit() {
        guard let reason else { return }
        isSubmitting = true
        errorMessage = nil
        Task {
            do {
                try await SafetyService.shared.report(
                    userId: userId, reason: reason,
                    details: details.trimmingCharacters(in: .whitespacesAndNewlines),
                    conversationId: conversationId)
                if alsoBlock { try await SafetyService.shared.block(userId: userId) }
                submitted = true
            } catch {
                errorMessage = "Couldn't send the report. Check your connection and try again."
            }
            isSubmitting = false
        }
    }
}

// MARK: - Blocked Members (Settings)

struct BlockedMembersView: View {
    @ObservedObject private var userService = UserService.shared
    @State private var members: [User] = []
    @State private var hasLoaded = false

    private var blockedIds: [String] { userService.currentUser?.blockedUserIds ?? [] }

    var body: some View {
        List {
            if hasLoaded && !members.contains(where: { blockedIds.contains($0.id) }) {
                Text("You haven't blocked anyone.")
                    .foregroundColor(.nmaSecondary)
            }
            ForEach(members.filter { blockedIds.contains($0.id) }) { member in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.fullname).foregroundColor(.nmaPrimary)
                        if !member.credentials.isEmpty {
                            Text(member.credentials).font(.caption).foregroundColor(.nmaSecondary)
                        }
                    }
                    Spacer()
                    Button("Unblock") {
                        Task { try? await SafetyService.shared.unblock(userId: member.id) }
                    }
                    .buttonStyle(.bordered)
                    .tint(.nmaPrimary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.nmaBackground)
        .navigationTitle("Blocked Members")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            var loaded: [User] = []
            for id in blockedIds {
                if let user = try? await UserService.fetchUser(withUid: id) { loaded.append(user) }
            }
            members = loaded
            hasLoaded = true
        }
    }
}
