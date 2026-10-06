//
//  SafetyViews.swift
//  MedTeam
//

import SwiftUI
import FirebaseFirestore

enum AppLinks {
    static let privacyPolicy = URL(string: "https://robertplummer-doxsquare.github.io/MedTeamApp/privacy.html")!
    static let termsOfUse = URL(string: "https://robertplummer-doxsquare.github.io/MedTeamApp/terms.html")!
}

// MARK: - Terms of Use

private let termsAgreementText: AttributedString = {
    let md = "I agree to the [Terms of Use](\(AppLinks.termsOfUse.absoluteString)) and [Privacy Policy](\(AppLinks.privacyPolicy.absoluteString)). There is no tolerance for abusive or objectionable content or behavior."
    return (try? AttributedString(markdown: md)) ?? AttributedString(md)
}()

/// "I agree" checkbox with links to the Terms and Privacy Policy.
struct TermsCheckbox: View {
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button { isOn.toggle() } label: {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22))
                    .foregroundColor(isOn ? .nmaPrimary : .nmaSecondary)
            }
            .accessibilityLabel("Agree to the Terms of Use")
            .accessibilityValue(isOn ? "Checked" : "Unchecked")
            Text(termsAgreementText)
                .font(.footnote)
                .foregroundColor(.nmaSecondary)
                .tint(.nmaPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

/// Shown once to accounts created before the Terms of Use existed.
struct TermsAgreementView: View {
    @State private var agreed = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 40))
                    .foregroundColor(.nmaPrimary)
                    .padding(.top, 48)
                Text("Community Terms")
                    .font(.title2).fontWeight(.semibold).foregroundColor(.nmaPrimary)
                Text("MedTeam is a professional community. To keep it safe:")
                    .foregroundColor(.nmaSecondary)
                VStack(alignment: .leading, spacing: 10) {
                    rule("No harassment, hate, threats, or sexual content.")
                    rule("No spam, scams, or fake profiles.")
                    rule("Never share patient information.")
                    rule("Report or block anyone who breaks these rules. We review reports within 24 hours and remove offending content and members.")
                }
                TermsCheckbox(isOn: $agreed).padding(.top, 8)
                if let errorMessage {
                    Text(errorMessage).font(.footnote).foregroundColor(.red)
                }
                Button { accept() } label: {
                    Group {
                        if isSaving { ProgressView().tint(.white) } else { Text("Continue").fontWeight(.semibold) }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(agreed ? Color.nmaPrimary : Color.nmaBorder)
                    .cornerRadius(12)
                }
                .disabled(!agreed || isSaving)
                Button("Log Out") { AuthService.shared.signOut() }
                    .font(.footnote)
                    .foregroundColor(.nmaSecondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.nmaBackground)
    }

    private func rule(_ text: String) -> some View {
        Label {
            Text(text).foregroundColor(.nmaPrimary).fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "checkmark.circle.fill").foregroundColor(.nmaPrimary)
        }
        .font(.subheadline)
    }

    private func accept() {
        isSaving = true
        errorMessage = nil
        Task {
            do {
                try await UserService.shared.updateFields(["termsAcceptedAt": Timestamp(date: Date())])
            } catch {
                errorMessage = "Couldn't save. Check your connection and try again."
            }
            isSaving = false
        }
    }
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
