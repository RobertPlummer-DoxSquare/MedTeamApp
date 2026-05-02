//
//  ExploreView.swift
//  MedTeam
//
//  Created by Robert Plummer on 6/24/24.
//
import SwiftUI

// MARK: - Filter Model

struct ExploreFilters {
    var specialty: String? = nil
    var practiceType: PracticeType? = nil
    var stateFilter: String? = nil
    var acceptingReferrals = false
    var availableMentor = false
    var openToCollaboration = false

    var isActive: Bool {
        specialty != nil || practiceType != nil || stateFilter != nil
        || acceptingReferrals || availableMentor || openToCollaboration
    }
}

// MARK: - Explore View

struct ExploreView: View {
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var filters = ExploreFilters()
    @StateObject var viewModel = ExploreViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Group {
                    if filteredUsers.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.largeTitle).foregroundColor(Color(white: 0.3))
                            Text("No providers found")
                                .font(.subheadline).foregroundColor(Color(white: 0.4))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(filteredUsers) { user in
                                    NavigationLink(destination: UserProfileView(user: user)) {
                                        UserProfileRow(user: user)
                                    }
                                    .buttonStyle(.plain)
                                    Divider()
                                        .background(Color(white: 0.12))
                                        .padding(.leading, 72)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search providers")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: filters.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundColor(filters.isActive ? .blue : Color(white: 0.6))
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterSheet(filters: $filters)
            }
        }
        .colorScheme(.dark)
    }

    var filteredUsers: [User] {
        var users = viewModel.users

        if !searchText.isEmpty {
            users = users.filter {
                $0.fullname.localizedCaseInsensitiveContains(searchText)
                || ($0.specialty ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
        if let spec = filters.specialty {
            users = users.filter { $0.specialty == spec }
        }
        if let pt = filters.practiceType {
            users = users.filter { $0.practiceType == pt }
        }
        if let state = filters.stateFilter {
            users = users.filter { $0.stateLicenses.contains(state) }
        }
        if filters.acceptingReferrals {
            users = users.filter { $0.isAcceptingReferrals }
        }
        if filters.availableMentor {
            users = users.filter { $0.isMentor }
        }
        if filters.openToCollaboration {
            users = users.filter { $0.isOpenToCollaboration }
        }
        return users
    }
}

// MARK: - User Profile Row

struct UserProfileRow: View {
    let user: User

    var body: some View {
        HStack(spacing: 12) {
            avatarView
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(user.fullname)
                        .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                    if user.npiVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue).font(.caption)
                    }
                }
                if let specialty = user.specialty {
                    Text(specialty)
                        .font(.caption).foregroundColor(Color(white: 0.5))
                }
                if let institution = user.currentInstitution, !institution.isEmpty {
                    Text(institution)
                        .font(.caption).foregroundColor(Color(white: 0.4))
                }
                if user.isAcceptingReferrals || user.isMentor {
                    HStack(spacing: 6) {
                        if user.isAcceptingReferrals {
                            Text("Referrals").font(.caption2).foregroundColor(.blue)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15)).cornerRadius(4)
                        }
                        if user.isMentor {
                            Text("Mentor").font(.caption2).foregroundColor(Color(white: 0.6))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color(white: 0.12)).cornerRadius(4)
                        }
                    }
                }
            }

            Spacer()

            Text(user.credentials)
                .font(.caption).fontWeight(.medium).foregroundColor(.blue)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
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
            .fill(Color(white: 0.18))
            .overlay(Text(initials).font(.system(size: 15, weight: .medium)).foregroundColor(.white))
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @Binding var filters: ExploreFilters
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                List {
                    // Specialty
                    Section("Specialty") {
                        Picker("Specialty", selection: $filters.specialty) {
                            Text("Any").tag(String?.none)
                            ForEach(medSpecialties, id: \.self) { spec in
                                Text(spec).tag(String?.some(spec))
                            }
                        }
                        .pickerStyle(.menu).tint(.white)
                    }

                    // Practice Type
                    Section("Practice Type") {
                        Picker("Practice Type", selection: $filters.practiceType) {
                            Text("Any").tag(PracticeType?.none)
                            ForEach(PracticeType.allCases, id: \.self) { pt in
                                Text(pt.rawValue).tag(PracticeType?.some(pt))
                            }
                        }
                        .pickerStyle(.menu).tint(.white)
                    }

                    // State
                    Section("State License") {
                        Picker("State", selection: $filters.stateFilter) {
                            Text("Any").tag(String?.none)
                            ForEach(usStates, id: \.self) { state in
                                Text(state).tag(String?.some(state))
                            }
                        }
                        .pickerStyle(.menu).tint(.white)
                    }

                    // Toggles
                    Section("Availability") {
                        Toggle("Accepting Referrals", isOn: $filters.acceptingReferrals)
                        Toggle("Available as Mentor", isOn: $filters.availableMentor)
                        Toggle("Open to Collaboration", isOn: $filters.openToCollaboration)
                    }

                    // Reset
                    Section {
                        Button("Reset Filters", role: .destructive) {
                            filters = ExploreFilters()
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .colorScheme(.dark)
        }
    }
}


struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
    }
}
