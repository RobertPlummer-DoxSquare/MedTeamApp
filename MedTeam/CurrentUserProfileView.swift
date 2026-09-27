//
//  CurrentUserProfileView.swift
//  MedTeam
//

import SwiftUI

struct CurrentUserProfileView: View {
    @StateObject var viewModel = CurrentUserProfileViewModel()
    @State private var isShowingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.nmaBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    if let user = viewModel.currentUser {
                        VStack(spacing: 0) {
                            if !user.isVerified {
                                verifyPrompt(user: user)
                            }
                            ProfileContent(user: user)
                            profileCompletion(user: user)
                        }
                        .padding(.bottom, 40)
                    } else {
                        ProgressView().tint(Color.nmaPrimary).padding(.top, 60)
                    }
                }
            }
            .navigationTitle("Me")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { isShowingSettings = true } label: {
                        Image(systemName: "gearshape").foregroundColor(Color.nmaPrimary)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $isShowingSettings) { Settings() }
        }
    }

    private func verifyPrompt(user: User) -> some View {
        NavigationLink {
            VerificationView(memberType: user.memberType)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.seal")
                    .font(.title3).foregroundColor(.regionBlue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Verify now").font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(Color.nmaPrimary)
                    Text(user.memberType == .student
                         ? "Confirm your school email to get the Verified student badge."
                         : "Confirm your NPI to get the Verified clinician badge.")
                        .font(.caption).foregroundColor(Color.nmaSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(Color.nmaSecondary)
            }
            .padding(14)
            .background(Color.regionBlueBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, 20).padding(.top, 12)
    }

    @ViewBuilder
    private func profileCompletion(user: User) -> some View {
        let missing = user.profileChecklist.filter { !$0.isDone }.map(\.item)
        if !missing.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Finish your profile").font(.caption).fontWeight(.semibold)
                    .foregroundColor(Color.nmaSecondary)
                ProgressView(value: Double(user.profileCompletionPercent), total: 100)
                    .tint(Color.nmaPrimary)
                    .accessibilityLabel("Profile \(user.profileCompletionPercent) percent complete")
                VStack(spacing: 0) {
                    ForEach(missing) { item in
                        NavigationLink {
                            destination(for: item, user: user)
                        } label: {
                            HStack {
                                Image(systemName: "circle").font(.caption).foregroundColor(Color.nmaSecondary)
                                Text(item.title(for: user.memberType))
                                    .font(.subheadline).foregroundColor(Color.nmaPrimary)
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption).foregroundColor(Color.nmaSecondary)
                            }
                            .padding(.horizontal, 14).padding(.vertical, 12)
                        }
                        if item != missing.last { Divider().padding(.leading, 14) }
                    }
                }
                .background(Color.nmaSurface)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.nmaBorder, lineWidth: 0.5))
            }
            .padding(.horizontal, 20).padding(.top, 20)
        }
    }

    @ViewBuilder
    private func destination(for item: ProfileItem, user: User) -> some View {
        switch item {
        case .verification:  VerificationView(memberType: user.memberType)
        case .specialty:     EditSpecialtyView()
        case .institution:   EditPracticeView()
        case .region:        EditRegionView()
        case .stateLicenses: EditLicensesView()
        case .languages:     EditLanguagesView()
        }
    }
}

struct CurrentUserProfileView_Previews: PreviewProvider {
    static var previews: some View { CurrentUserProfileView() }
}
