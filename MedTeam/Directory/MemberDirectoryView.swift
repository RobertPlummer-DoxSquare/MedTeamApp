//
//  MemberDirectoryView.swift
//  MedTeam
//

import SwiftUI

// MARK: - Filters

struct DirectoryFilters {
    var specialty: String? = nil
    var region: NMARegion? = nil
    var openToResearch = false
    var availableAsMentor = false
    var acceptsReferrals = false

    var isActive: Bool {
        specialty != nil || region != nil || openToResearch || availableAsMentor || acceptsReferrals
    }
}

// MARK: - Main View

struct MemberDirectoryView: View {
    @StateObject private var viewModel = MemberDirectoryViewModel()
    @State private var searchText = ""
    @State private var showAllMembers = false
    @State private var showFilters = false
    @State private var filters = DirectoryFilters()

    private var currentUserRegion: NMARegion? {
        UserService.shared.currentUser?.nmaRegion
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.nmaBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    if let region = currentUserRegion, !showAllMembers {
                        RegionMapHeaderView(region: region)
                            .zIndex(1)
                        Divider().foregroundColor(Color.nmaBorder).padding(.top, 20)
                    } else {
                        Divider().foregroundColor(Color.nmaBorder)
                    }

                    scopeToggle

                    Divider().foregroundColor(Color.nmaBorder)

                    if filteredUsers.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(filteredUsers) { user in
                                    NavigationLink(destination: UserProfileView(user: user)) {
                                        MemberRowView(user: user)
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
            .navigationTitle("Directory")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search members")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showFilters = true } label: {
                        Image(systemName: filters.isActive
                            ? "line.3.horizontal.decrease.circle.fill"
                            : "line.3.horizontal.decrease.circle")
                            .foregroundColor(filters.isActive ? Color.nmaPrimary : Color.nmaSecondary)
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                DirectoryFilterSheet(filters: $filters, showAllMembers: showAllMembers)
            }
        }
    }

    // MARK: - Scope Toggle

    private var scopeToggle: some View {
        Picker("Show", selection: $showAllMembers.animation()) {
            Text("My Region").tag(false)
            Text("All NMA Members").tag(true)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.nmaBackground)
    }

    // MARK: - Filtered Users

    var filteredUsers: [User] {
        var users = viewModel.users

        // Exclude current user
        if let uid = UserService.shared.currentUser?.id {
            users = users.filter { $0.id != uid }
        }

        // Region scope
        if !showAllMembers, let region = currentUserRegion {
            users = users.filter { $0.nmaRegion == region }
        }

        // Search
        if !searchText.isEmpty {
            users = users.filter {
                $0.fullname.localizedCaseInsensitiveContains(searchText)
                || ($0.specialty ?? "").localizedCaseInsensitiveContains(searchText)
                || ($0.currentInstitution ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }

        // Filters
        if let spec = filters.specialty    { users = users.filter { $0.specialty == spec } }
        if let reg  = filters.region       { users = users.filter { $0.nmaRegion == reg } }
        if filters.openToResearch          { users = users.filter { $0.isOpenToCollaboration } }
        if filters.availableAsMentor       { users = users.filter { $0.isMentor } }
        if filters.acceptsReferrals        { users = users.filter { $0.isOpenToReferrals } }

        // Chairpersons first
        return users.sorted { $0.isChairperson && !$1.isChairperson }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.2")
                .font(.largeTitle).foregroundColor(Color.nmaSecondary)
            Text(showAllMembers ? "No members found" : "No members in your region yet")
                .font(.subheadline).foregroundColor(Color.nmaSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - Region Banner

struct RegionBannerView: View {
    let region: NMARegion

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(region.displayName)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(region.badgeForeground)
                Spacer()
                if region.nextMeeting != "TBD" {
                    Text("Next meeting")
                        .font(.caption2).foregroundColor(region.badgeForeground.opacity(0.7))
                }
            }
            Text(region.statesDisplay)
                .font(.caption).foregroundColor(region.badgeForeground.opacity(0.75))
                .lineLimit(2)
            HStack {
                Label(region.chairName, systemImage: "person.fill")
                    .font(.caption).foregroundColor(region.badgeForeground.opacity(0.85))
                Spacer()
                if region.nextMeeting != "TBD" {
                    Text(region.nextMeeting)
                        .font(.caption).foregroundColor(region.badgeForeground.opacity(0.85))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(region.badgeBackground)
    }
}

// MARK: - Member Row

struct MemberRowView: View {
    let user: User

    var body: some View {
        HStack(spacing: 12) {
            avatarView
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(user.fullname)
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(.nmaPrimary)
                    if user.isVerified {
                        VerificationBadge(memberType: user.memberType, compact: true)
                    }
                    if user.isChairperson {
                        Text("Chair")
                            .font(.caption2).fontWeight(.semibold)
                            .foregroundColor(Color.chairGold)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.chairGoldBackground)
                            .cornerRadius(4)
                    }
                }

                if let specialty = user.specialty {
                    Text(specialty)
                        .font(.caption).foregroundColor(Color.nmaSecondary)
                }
                if let institution = user.currentInstitution, !institution.isEmpty {
                    Text(institution)
                        .font(.caption).foregroundColor(Color.nmaSecondary.opacity(0.7))
                }

                HStack(spacing: 6) {
                    if user.isOpenToReferrals {
                        availabilityBadge("Referrals", color: Color.referralGreen, bg: Color.referralGreenBackground)
                    }
                    if user.isMentor {
                        availabilityBadge("Mentor", color: Color.nmaSecondary, bg: Color.nmaSubtle)
                    }
                    if user.isOpenToCollaboration {
                        availabilityBadge("Research", color: Color.researchPurple, bg: Color.researchPurpleBackground)
                    }
                }
                .padding(.top, 2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let region = user.nmaRegion {
                    trailingRegionBadge(region)
                }
                Text(user.credentials)
                    .font(.caption).fontWeight(.medium)
                    .foregroundColor(Color.nmaSecondary)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .background(Color.nmaBackground)
    }

    @ViewBuilder
    private func trailingRegionBadge(_ region: NMARegion) -> some View {
        let numeral: String = {
            switch region {
            case .regionI:   return "R1"
            case .regionII:  return "R2"
            case .regionIII: return "R3"
            case .regionIV:  return "R4"
            case .regionV:   return "R5"
            case .regionVI:  return "R6"
            }
        }()
        Text(user.isChairperson ? "\(numeral) Chair" : numeral)
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(Color.regionBlue)
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background(Color.regionBlueBackground)
            .cornerRadius(4)
    }

    @ViewBuilder
    private func availabilityBadge(_ label: String, color: Color, bg: Color) -> some View {
        Text(label)
            .font(.caption2)
            .foregroundColor(color)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(bg)
            .cornerRadius(4)
    }

    @ViewBuilder
    private var avatarView: some View {
        if let imageUrl = user.profileImageUrl, let url = URL(string: imageUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill).clipShape(Circle())
                default:
                    initialsCircle
                }
            }
        } else {
            initialsCircle
        }
    }

    private var initialsCircle: some View {
        let initials = user.fullname
            .components(separatedBy: " ").compactMap { $0.first }.prefix(2).map(String.init).joined()
        return Circle()
            .fill(Color.regionBlueBackground)
            .overlay(
                Text(initials)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.regionBlue)
            )
    }
}

// MARK: - Filter Sheet

struct DirectoryFilterSheet: View {
    @Binding var filters: DirectoryFilters
    let showAllMembers: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Specialty") {
                    Picker("Specialty", selection: $filters.specialty) {
                        Text("Any").tag(String?.none)
                        ForEach(medSpecialties, id: \.self) { Text($0).tag(String?.some($0)) }
                    }
                    .pickerStyle(.menu)
                }
                if showAllMembers {
                    Section("Region") {
                        Picker("Region", selection: $filters.region) {
                            Text("Any").tag(NMARegion?.none)
                            ForEach(NMARegion.allCases, id: \.self) {
                                Text($0.displayName).tag(NMARegion?.some($0))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                Section("Availability") {
                    Toggle("Open to research collaboration", isOn: $filters.openToResearch)
                    Toggle("Available as mentor", isOn: $filters.availableAsMentor)
                    Toggle("Accept referral notifications", isOn: $filters.acceptsReferrals)
                }
                Section {
                    Button("Reset Filters", role: .destructive) { filters = DirectoryFilters() }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
