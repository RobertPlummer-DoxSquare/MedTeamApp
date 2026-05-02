//
//  UserProfileView.swift
//  MedTeam
//

import SwiftUI

struct UserProfileView: View {
    let user: User
    @State private var showPingSheet = false

    private var availablePingTypes: [PingType] {
        var types: [PingType] = []
        if user.isAcceptingReferrals  { types.append(.referral) }
        if user.isMentor              { types.append(.mentorship) }
        if user.isOpenToCollaboration { types.append(.collaboration) }
        return types
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    profileHeader
                    if !availablePingTypes.isEmpty {
                        pingButton
                    }
                    profileBody
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .colorScheme(.dark)
        .sheet(isPresented: $showPingSheet) {
            PingSheetView(targetUser: user)
        }
    }

    // MARK: - Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color(white: 0.15))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(initials(for: user.fullname))
                        .font(.title3).fontWeight(.semibold).foregroundColor(.white)
                )
                .padding(.top, 16)

            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text(user.fullname)
                        .font(.title3).fontWeight(.semibold).foregroundColor(.white)
                    if user.npiVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue).font(.subheadline)
                    }
                }
                Text("@\(user.username)")
                    .font(.subheadline).foregroundColor(Color(white: 0.45))
            }

            HStack(spacing: 8) {
                if let specialty = user.specialty {
                    infoChip(specialty, color: .blue)
                }
                if let pt = user.practiceType {
                    infoChip(pt.rawValue, color: Color(white: 0.25))
                }
            }

            if let institution = user.currentInstitution, !institution.isEmpty {
                Text(institution)
                    .font(.subheadline).foregroundColor(Color(white: 0.5))
            }

            if !user.stateLicenses.isEmpty {
                Text(user.stateLicenses.joined(separator: " · "))
                    .font(.caption).foregroundColor(Color(white: 0.4))
            }

            if user.isAcceptingReferrals || user.isOpenToCollaboration || user.isMentor {
                HStack(spacing: 8) {
                    if user.isAcceptingReferrals {
                        badgeView("Referrals", icon: "arrow.left.arrow.right.circle")
                    }
                    if user.isOpenToCollaboration {
                        badgeView("Collab", icon: "flask")
                    }
                    if user.isMentor {
                        badgeView("Mentor", icon: "graduationcap")
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: - Ping Button

    private var pingButton: some View {
        Button {
            showPingSheet = true
        } label: {
            Text("Ping \(user.fullname.components(separatedBy: " ").first ?? user.fullname)")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Body

    private var profileBody: some View {
        VStack(spacing: 0) {
            separator

            if user.medicalSchool != nil || user.residencyProgram != nil {
                profileSection(title: "Training") {
                    if let school = user.medicalSchool {
                        trainingRow(title: school,
                                    detail: user.medicalSchoolGradYear.map { "Class of \($0)" })
                    }
                    if let res = user.residencyProgram {
                        trainingRow(title: res,
                                    detail: user.residencyCompletionYear.map { "Residency · \($0)" })
                    }
                    if let fel = user.fellowshipProgram {
                        trainingRow(title: fel,
                                    detail: user.fellowshipCompletionYear.map { "Fellowship · \($0)" })
                    }
                }
                separator
            }

            if !user.boardCertifications.isEmpty {
                profileSection(title: "Board Certifications") {
                    ForEach(user.boardCertifications, id: \.self) { cert in
                        Text(cert)
                            .font(.subheadline).foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24).padding(.vertical, 4)
                    }
                }
                separator
            }

            if !user.languagesSpoken.isEmpty {
                profileSection(title: "Languages") {
                    Text(user.languagesSpoken.joined(separator: " · "))
                        .font(.subheadline).foregroundColor(Color(white: 0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                }
                separator
            }
        }
        .padding(.bottom, 40)
    }

    // MARK: - Helpers

    private var separator: some View {
        Divider().background(Color(white: 0.12)).padding(.horizontal, 24)
    }

    @ViewBuilder
    private func profileSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption).fontWeight(.semibold)
                .foregroundColor(Color(white: 0.4))
                .padding(.horizontal, 24).padding(.top, 20)
            content()
                .padding(.bottom, 16)
        }
    }

    @ViewBuilder
    private func trainingRow(title: String, detail: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.subheadline).foregroundColor(.white)
            if let detail {
                Text(detail).font(.caption).foregroundColor(Color(white: 0.45))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24).padding(.vertical, 2)
    }

    @ViewBuilder
    private func infoChip(_ label: String, color: Color) -> some View {
        Text(label)
            .font(.caption).fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(color.opacity(0.3))
            .cornerRadius(8)
    }

    @ViewBuilder
    private func badgeView(_ label: String, icon: String) -> some View {
        Label(label, systemImage: icon)
            .font(.caption).fontWeight(.medium)
            .foregroundColor(Color(white: 0.7))
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Color(white: 0.1))
            .cornerRadius(8)
    }

    private func initials(for name: String) -> String {
        name.components(separatedBy: " ").compactMap { $0.first }.prefix(2).map(String.init).joined()
    }
}
