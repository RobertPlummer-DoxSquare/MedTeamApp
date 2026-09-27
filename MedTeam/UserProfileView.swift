//
//  UserProfileView.swift
//  MedTeam
//

import SwiftUI

// MARK: - Shared Profile Content

/// The profile layout used both for your own profile and for other members.
struct ProfileContent: View {
    let user: User

    var body: some View {
        VStack(spacing: 0) {
            header
            details
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ProfileAvatar(user: user, size: 80)
                .padding(.top, 20)

            VStack(spacing: 4) {
                Text(user.fullname)
                    .font(.title3).fontWeight(.semibold).foregroundColor(Color.nmaPrimary)
                if !user.credentials.isEmpty {
                    Text(user.credentials)
                        .font(.subheadline).foregroundColor(Color.nmaSecondary)
                }
                if user.isVerified {
                    VerificationBadge(memberType: user.memberType)
                        .padding(.top, 2)
                }
            }

            HStack(spacing: 8) {
                if let specialty = user.specialty, !specialty.isEmpty { infoChip(specialty) }
                if let pt = user.practiceType { infoChip(pt.rawValue) }
            }

            if let institution = user.currentInstitution, !institution.isEmpty {
                Text(institution).font(.subheadline).foregroundColor(Color.nmaSecondary)
            }

            availabilityBadges
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    @ViewBuilder
    private var availabilityBadges: some View {
        if user.isOpenToReferrals || user.isOpenToCollaboration || user.isMentor {
            HStack(spacing: 8) {
                if user.isMentor {
                    availBadge("Mentoring", icon: "graduationcap",
                               fg: .regionBlue, bg: .regionBlueBackground)
                }
                if user.isOpenToCollaboration {
                    availBadge("Research", icon: "flask",
                               fg: .researchPurple, bg: .researchPurpleBackground)
                }
                if user.isOpenToReferrals {
                    availBadge("Referrals", icon: "phone",
                               fg: .referralGreen, bg: .referralGreenBackground)
                }
            }
            .padding(.top, 4)
        }
    }

    private var details: some View {
        VStack(spacing: 0) {
            separator

            if let region = user.nmaRegion {
                section("NMA Region") {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            regionBadge(region)
                            if user.isChairperson { chairBadge }
                        }
                        Text("Chair: \(region.chairName)")
                            .font(.caption).foregroundColor(Color.nmaSecondary)
                        if region.nextMeeting != "TBD" {
                            Text("Next meeting: \(region.nextMeeting)")
                                .font(.caption).foregroundColor(Color.nmaSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                }
                separator
            }

            if user.medicalSchool?.isEmpty == false || user.residencyProgram?.isEmpty == false {
                section("Training") {
                    if let school = user.medicalSchool, !school.isEmpty {
                        trainingRow(title: school, detail: user.medicalSchoolGradYear.map { "Class of \($0)" })
                    }
                    if let res = user.residencyProgram, !res.isEmpty {
                        trainingRow(title: res, detail: user.residencyCompletionYear.map { "Residency · \($0)" })
                    }
                    if let fel = user.fellowshipProgram, !fel.isEmpty {
                        trainingRow(title: fel, detail: user.fellowshipCompletionYear.map { "Fellowship · \($0)" })
                    }
                }
                separator
            }

            if !user.boardCertifications.isEmpty {
                section("Board Certifications") {
                    ForEach(user.boardCertifications, id: \.self) { cert in
                        Text(cert).font(.subheadline).foregroundColor(Color.nmaPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24).padding(.vertical, 2)
                    }
                }
                separator
            }

            if !user.stateLicenses.isEmpty {
                section("State Licenses") {
                    Text(user.stateLicenses.joined(separator: " · "))
                        .font(.subheadline).foregroundColor(Color.nmaPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                }
                separator
            }

            if !user.languagesSpoken.isEmpty {
                section("Languages") {
                    Text(user.languagesSpoken.joined(separator: " · "))
                        .font(.subheadline).foregroundColor(Color.nmaPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                }
                separator
            }
        }
    }

    // MARK: - Helpers

    private var separator: some View {
        Divider().background(Color.nmaBorder).padding(.horizontal, 24)
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.caption).fontWeight(.semibold)
                .foregroundColor(Color.nmaSecondary)
                .padding(.horizontal, 24).padding(.top, 20)
            content().padding(.bottom, 16)
        }
    }

    private func trainingRow(title: String, detail: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.subheadline).foregroundColor(Color.nmaPrimary)
            if let detail { Text(detail).font(.caption).foregroundColor(Color.nmaSecondary) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24).padding(.vertical, 2)
    }

    private func infoChip(_ label: String) -> some View {
        Text(label).font(.caption).fontWeight(.medium)
            .foregroundColor(Color.nmaSecondary)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Color.nmaSubtle).cornerRadius(8)
    }

    private func regionBadge(_ region: NMARegion) -> some View {
        Text(region.displayName)
            .font(.caption).fontWeight(.medium)
            .foregroundColor(region.badgeForeground)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(region.badgeBackground)
            .cornerRadius(6)
    }

    private var chairBadge: some View {
        Label("Chairperson", systemImage: "star.fill")
            .font(.caption).fontWeight(.medium)
            .foregroundColor(.chairGold)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Color.chairGoldBackground)
            .cornerRadius(6)
    }

    private func availBadge(_ label: String, icon: String, fg: Color, bg: Color) -> some View {
        Label(label, systemImage: icon)
            .font(.caption).fontWeight(.medium)
            .foregroundColor(fg)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(bg).cornerRadius(6)
    }
}

// MARK: - Verification Badge

/// Blue "Verified clinician" or green "Verified student".
struct VerificationBadge: View {
    let memberType: MemberType
    var compact = false

    private var label: String { memberType == .student ? "Verified student" : "Verified clinician" }
    private var fg: Color { memberType == .student ? .referralGreen : .regionBlue }
    private var bg: Color { memberType == .student ? .referralGreenBackground : .regionBlueBackground }

    var body: some View {
        if compact {
            Image(systemName: "checkmark.seal.fill")
                .font(.caption)
                .foregroundColor(fg)
                .accessibilityLabel(label)
        } else {
            Label(label, systemImage: "checkmark.seal.fill")
                .font(.caption).fontWeight(.medium)
                .foregroundColor(fg)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(bg).cornerRadius(6)
        }
    }
}

// MARK: - Avatar

/// Profile photo when available, otherwise initials.
struct ProfileAvatar: View {
    let user: User
    let size: CGFloat

    var body: some View {
        Group {
            if let urlString = user.profileImageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        initials
                    }
                }
            } else {
                initials
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityLabel("Photo of \(user.fullname)")
    }

    private var initials: some View {
        Circle()
            .fill(Color.regionBlueBackground)
            .overlay(
                Text(user.fullname.components(separatedBy: " ").compactMap { $0.first }
                        .prefix(2).map(String.init).joined())
                    .font(size > 50 ? .title3 : .caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.regionBlue)
            )
    }
}

// MARK: - Another Member's Profile

struct UserProfileView: View {
    let user: User
    @State private var showConnectSheet = false

    private var canConnect: Bool { user.isMentor || user.isOpenToCollaboration }

    private var officePhoneURL: URL? {
        guard user.isOpenToReferrals, let phone = user.officePhone, !phone.isEmpty else { return nil }
        return URL(string: "tel:\(phone.filter { $0.isNumber || $0 == "+" })")
    }

    var body: some View {
        ZStack {
            Color.nmaBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ProfileContent(user: user)
                    actions
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showConnectSheet) {
            ConnectSheetView(targetUser: user)
        }
    }

    @ViewBuilder
    private var actions: some View {
        VStack(spacing: 10) {
            if canConnect {
                Button { showConnectSheet = true } label: {
                    Label("Connect", systemImage: "person.badge.plus")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity).frame(height: 48)
                        .background(Color.nmaPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }

            if let url = officePhoneURL {
                Link(destination: url) {
                    Label("Call office for referrals", systemImage: "phone.fill")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity).frame(height: 48)
                        .background(Color.referralGreenBackground)
                        .foregroundColor(.referralGreen)
                        .cornerRadius(12)
                }
            }

            if !canConnect && officePhoneURL == nil {
                Text("Not accepting requests right now")
                    .font(.subheadline).fontWeight(.medium)
                    .frame(maxWidth: .infinity).frame(height: 48)
                    .background(Color.nmaSubtle)
                    .foregroundColor(Color.nmaSecondary)
                    .cornerRadius(12)
            }
        }
    }
}
