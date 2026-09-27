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

    private func profileCompletion(user: User) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Profile Completion").font(.caption).fontWeight(.semibold)
                .foregroundColor(Color.nmaSecondary)
            ProgressView(value: Double(user.profileCompletionPercent), total: 100)
                .tint(Color.nmaPrimary)
            Text("\(user.profileCompletionPercent)% complete")
                .font(.caption).foregroundColor(Color.nmaSecondary)
        }
        .padding(.horizontal, 24).padding(.top, 20)
    }
}

struct CurrentUserProfileView_Previews: PreviewProvider {
    static var previews: some View { CurrentUserProfileView() }
}
