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
                            profileHeader(user: user)
                            profileBody(user: user)
                        }
                    } else {
                        ProgressView().tint(Color.nmaPrimary).padding(.top, 60)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { isShowingSettings = true } label: {
                        Image(systemName: "gearshape").foregroundColor(Color.nmaPrimary)
                    }
                }
            }
            .sheet(isPresented: $isShowingSettings) { Settings() }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func profileHeader(user: User) -> some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Color.nmaSubtle)
                .frame(width: 80, height: 80)
                .overlay(
                    Text(initials(for: user.fullname))
                        .font(.title3).fontWeight(.semibold).foregroundColor(Color.nmaSecondary)
                )

            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text(user.fullname)
                        .font(.title3).fontWeight(.semibold).foregroundColor(Color.nmaPrimary)
                    if user.npiVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue).font(.subheadline)
                    }
                }
                Text("@\(user.username)")
                    .font(.subheadline).foregroundColor(Color.nmaSecondary)
            }

            HStack(spacing: 8) {
                if let specialty = user.specialty { infoChip(specialty) }
                if let pt = user.practiceType { infoChip(pt.rawValue) }
            }

            if let institution = user.currentInstitution, !institution.isEmpty {
                Text(institution).font(.subheadline).foregroundColor(Color.nmaSecondary)
            }

            // Region badge
            if let region = user.nmaRegion {
                HStack(spacing: 6) {
                    regionBadge(region)
                    if user.isChairperson { chairBadge }
                }
            }

            if !user.stateLicenses.isEmpty {
                Text(user.stateLicenses.joined(separator: " · "))
                    .font(.caption).foregroundColor(Color.nmaSecondary.opacity(0.7))
            }

            // Availability badges
            if user.isOpenToReferrals || user.isOpenToCollaboration || user.isMentor {
                HStack(spacing: 8) {
                    if user.isOpenToReferrals {
                        availBadge("Referrals: Call my office", icon: "phone.circle",
                                   fg: Color.referralGreen, bg: Color.referralGreenBackground)
                    }
                    if user.isOpenToCollaboration {
                        availBadge("Research", icon: "flask",
                                   fg: Color.researchPurple, bg: Color.researchPurpleBackground)
                    }
                    if user.isMentor {
                        availBadge("Mentor", icon: "graduationcap",
                                   fg: Color.nmaSecondary, bg: Color.nmaSubtle)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.bottom, 24)
    }

    // MARK: - Body

    @ViewBuilder
    private func profileBody(user: User) -> some View {
        VStack(spacing: 0) {
            separator

            if let region = user.nmaRegion {
                profileSection(title: "NMA Region") {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            regionBadge(region)
                            if user.isChairperson { chairBadge }
                        }
                        .padding(.horizontal, 24)
                        Text("Chair: \(region.chairName)")
                            .font(.caption).foregroundColor(Color.nmaSecondary).padding(.horizontal, 24)
                        if region.nextMeeting != "TBD" {
                            Text("Next meeting: \(region.nextMeeting)")
                                .font(.caption).foregroundColor(Color.nmaSecondary.opacity(0.7))
                                .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 4)
                }
                separator
            }

            if user.medicalSchool != nil || user.residencyProgram != nil {
                profileSection(title: "Training") {
                    if let school = user.medicalSchool {
                        trainingRow(title: school, detail: user.medicalSchoolGradYear.map { "Class of \($0)" })
                    }
                    if let res = user.residencyProgram {
                        trainingRow(title: res, detail: user.residencyCompletionYear.map { "Residency · \($0)" })
                    }
                    if let fel = user.fellowshipProgram {
                        trainingRow(title: fel, detail: user.fellowshipCompletionYear.map { "Fellowship · \($0)" })
                    }
                }
                separator
            }

            if !user.boardCertifications.isEmpty {
                profileSection(title: "Board Certifications") {
                    ForEach(user.boardCertifications, id: \.self) { cert in
                        Text(cert).font(.subheadline).foregroundColor(Color.nmaPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24).padding(.vertical, 4)
                    }
                }
                separator
            }

            if !user.languagesSpoken.isEmpty {
                profileSection(title: "Languages") {
                    Text(user.languagesSpoken.joined(separator: " · "))
                        .font(.subheadline).foregroundColor(Color.nmaSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 24)
                }
                separator
            }

            profileSection(title: "Profile Completion") {
                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.nmaBorder).frame(height: 6)
                            Capsule().fill(Color.nmaPrimary)
                                .frame(width: geo.size.width * CGFloat(user.profileCompletionPercent) / 100, height: 6)
                        }
                    }
                    .frame(height: 6)
                    Text("\(user.profileCompletionPercent)% complete")
                        .font(.caption).foregroundColor(Color.nmaSecondary)
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.bottom, 40)
    }

    // MARK: - Sub-components

    private var separator: some View {
        Divider().background(Color.nmaBorder).padding(.horizontal, 24)
    }

    @ViewBuilder
    private func profileSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.caption).fontWeight(.semibold)
                .foregroundColor(Color.nmaSecondary)
                .padding(.horizontal, 24).padding(.top, 20)
            content().padding(.bottom, 16)
        }
    }

    @ViewBuilder
    private func trainingRow(title: String, detail: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.subheadline).foregroundColor(Color.nmaPrimary)
            if let detail { Text(detail).font(.caption).foregroundColor(Color.nmaSecondary) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24).padding(.vertical, 2)
    }

    @ViewBuilder
    private func infoChip(_ label: String) -> some View {
        Text(label).font(.caption).fontWeight(.medium)
            .foregroundColor(Color.nmaSecondary)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Color.nmaSubtle).cornerRadius(8)
    }

    @ViewBuilder
    private func regionBadge(_ region: NMARegion) -> some View {
        Text(region.displayName)
            .font(.caption).fontWeight(.medium)
            .foregroundColor(region.badgeForeground)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(region.badgeBackground).cornerRadius(6)
    }

    private var chairBadge: some View {
        Label("Chairperson", systemImage: "star.fill")
            .font(.caption).fontWeight(.medium)
            .foregroundColor(Color.chairGold)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Color.chairGoldBackground).cornerRadius(6)
    }

    @ViewBuilder
    private func availBadge(_ label: String, icon: String, fg: Color, bg: Color) -> some View {
        Label(label, systemImage: icon)
            .font(.caption).fontWeight(.medium).foregroundColor(fg)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(bg).cornerRadius(6)
    }

    private func initials(for name: String) -> String {
        name.components(separatedBy: " ").compactMap { $0.first }.prefix(2).map(String.init).joined()
    }
}

struct CurrentUserProfileView_Previews: PreviewProvider {
    static var previews: some View { CurrentUserProfileView() }
}
