//
//  Settings.swift
//  MedTeam
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

// MARK: - SettingsViewModel

class SettingsViewModel: ObservableObject {
    @Published var isOpenToReferrals = false
    @Published var openToCollaboration = false
    @Published var isMentor = false
    @Published var officePhone = ""
    @Published var nmaRegion: NMARegion?
    @Published var user: User?

    private var cancellables = Set<AnyCancellable>()

    init() {
        UserService.shared.$currentUser
            .receive(on: RunLoop.main)
            .sink { [weak self] user in
                self?.user = user
                self?.isOpenToReferrals   = user?.isOpenToReferrals ?? false
                self?.openToCollaboration = user?.isOpenToCollaboration ?? false
                self?.isMentor            = user?.isMentor ?? false
                self?.officePhone         = user?.officePhone ?? ""
                self?.nmaRegion           = user?.nmaRegion
            }
            .store(in: &cancellables)
    }
}

// MARK: - Settings

struct Settings: View {
    @StateObject var viewModel = SettingsViewModel()
    @StateObject private var saver = AutoSaver()
    @State private var showDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Profile") {
                    NavigationLink("Specialty & Credentials") { EditSpecialtyView() }
                    NavigationLink("Practice & Institution")  { EditPracticeView() }
                    NavigationLink("State Licenses")          { EditLicensesView() }
                    NavigationLink("Languages")               { EditLanguagesView() }
                }

                Section("NMA Region") {
                    Picker("Region", selection: $viewModel.nmaRegion) {
                        Text("Not set").tag(NMARegion?.none)
                        ForEach(NMARegion.allCases, id: \.self) { region in
                            Text(region.displayName).tag(NMARegion?.some(region))
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: viewModel.nmaRegion) { region in
                        guard region != viewModel.user?.nmaRegion else { return }
                        saver.save(["nmaRegion": region?.rawValue ?? FieldValue.delete()])
                    }
                }

                Section {
                    Toggle("Accept referral notifications", isOn: $viewModel.isOpenToReferrals)
                        .onChange(of: viewModel.isOpenToReferrals) { on in
                            guard on != viewModel.user?.isOpenToReferrals else { return }
                            saver.save(["isAcceptingReferrals": on])
                        }

                    if viewModel.isOpenToReferrals {
                        TextField("Office phone", text: $viewModel.officePhone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .foregroundColor(.nmaPrimary)
                            .onChange(of: viewModel.officePhone) { phone in
                                guard phone != (viewModel.user?.officePhone ?? "") else { return }
                                saver.save(["officePhone": phone], after: .milliseconds(800))
                            }
                    }

                    Toggle("Open to research collaboration", isOn: $viewModel.openToCollaboration)
                        .onChange(of: viewModel.openToCollaboration) { on in
                            guard on != viewModel.user?.isOpenToCollaboration else { return }
                            saver.save(["isOpenToCollaboration": on])
                        }

                    Toggle("Available as mentor", isOn: $viewModel.isMentor)
                        .onChange(of: viewModel.isMentor) { on in
                            guard on != viewModel.user?.isMentor else { return }
                            saver.save(["isMentor": on])
                        }
                } header: {
                    Text("Availability")
                } footer: {
                    Text("Changes save automatically.")
                }
                .tint(Color.nmaPrimary)

                Section("Verification") {
                    NavigationLink {
                        NPIVerificationView()
                    } label: {
                        HStack {
                            Text("NPI Verification")
                            Spacer()
                            switch viewModel.user?.npiStatus {
                            case .verified:
                                Label("Verified", systemImage: "checkmark.seal.fill")
                                    .font(.caption).foregroundColor(.referralGreen)
                            case .pendingReview:
                                Label("Pending review", systemImage: "clock")
                                    .font(.caption).foregroundColor(.pendingAmber)
                            default:
                                EmptyView()
                            }
                        }
                    }
                }

                Section("Account") {
                    Button("Log Out", role: .destructive) { AuthService.shared.signOut() }
                    Button("Delete Account", role: .destructive) { showDeleteConfirmation = true }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.nmaBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.nmaPrimary)
                }
            }
            .saveStatus(saver)
            .sheet(isPresented: $showDeleteConfirmation) {
                DeleteAccountView()
            }
        }
    }
}

// MARK: - NPI Verification View

struct NPIVerificationView: View {
    @State private var npiInput = UserService.shared.currentUser?.npiNumber ?? ""
    @State private var lookupState: LookupState = .idle
    @State private var result: NPIResult?
    @State private var nameMatches = false

    var body: some View {
        ZStack {
            Color.nmaBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Enter your 10-digit NPI to verify your identity.")
                        .font(.subheadline).foregroundColor(Color.nmaSecondary)
                        .padding(.horizontal, 24).padding(.top, 16)

                    TextField("NPI Number", text: $npiInput)
                        .keyboardType(.numberPad)
                        .modifier(TextFieldModifier())

                    switch lookupState {
                    case .success:
                        if let r = result {
                            HStack(spacing: 12) {
                                Image(systemName: nameMatches
                                      ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                                    .foregroundColor(nameMatches ? .referralGreen : .pendingAmber)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(r.fullName).font(.subheadline).fontWeight(.semibold)
                                        .foregroundColor(Color.nmaPrimary)
                                    Text(r.specialty).font(.caption).foregroundColor(Color.nmaSecondary)
                                }
                            }
                            .padding(14)
                            .background(Color.nmaSurface)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.nmaBorder, lineWidth: 0.5))
                            .padding(.horizontal, 24)

                            if !nameMatches {
                                NPINameMismatchNote(registryName: r.fullName)
                            }
                        }
                    case .failure(let msg):
                        Text(msg).font(.caption).foregroundColor(.red).padding(.horizontal, 24)
                    default: EmptyView()
                    }

                    Button {
                        Task {
                            lookupState = .loading
                            do {
                                let lookup = try await NPIService.lookup(npi: npiInput)
                                let accountName = UserService.shared.currentUser?.fullname ?? ""
                                let matches = NPIService.nameMatches(lookup, accountName: accountName)
                                let status: NPIStatus = matches ? .verified : .pendingReview
                                let uid = Auth.auth().currentUser?.uid ?? ""
                                try await Firestore.firestore().collection("users").document(uid)
                                    .updateData([
                                        "npiNumber": npiInput,
                                        "npiVerified": matches,
                                        "npiStatus": status.rawValue
                                    ])
                                try await UserService.shared.fetchCurrentUser()
                                result = lookup
                                nameMatches = matches
                                lookupState = .success
                            } catch {
                                lookupState = .failure(error.localizedDescription)
                            }
                        }
                    } label: {
                        Group {
                            if lookupState == .loading { ProgressView().tint(.white) }
                            else { Text("Verify NPI").font(.subheadline).fontWeight(.semibold).foregroundColor(.white) }
                        }
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Color.nmaPrimary).cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .disabled(lookupState == .loading)
                }
            }
        }
        .navigationTitle("NPI Verification")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - NPI Name Mismatch Note

struct NPINameMismatchNote: View {
    let registryName: String

    var body: some View {
        Text("The name on this NPI (\(registryName)) doesn't match your account name, so we can't show a Verified badge yet. Your NPI has been saved for review.")
            .font(.caption)
            .foregroundColor(Color.nmaSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 24)
    }
}

// MARK: - Edit Specialty View

struct EditSpecialtyView: View {
    @State private var specialty = UserService.shared.currentUser?.specialty ?? ""
    @State private var degreeType = UserService.shared.currentUser?.degreeType ?? .md
    @State private var subspecialties = UserService.shared.currentUser?.subspecialties ?? []
    @State private var boardCertifications = UserService.shared.currentUser?.boardCertifications ?? []
    @State private var newCert = ""
    @StateObject private var saver = AutoSaver()

    var body: some View {
        ZStack {
            Color.nmaBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Degree").font(.caption).foregroundColor(Color.nmaSecondary)
                        .padding(.horizontal, 24).padding(.top, 16)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(DegreeType.allCases, id: \.self) { deg in
                                degreeChip(deg)
                            }
                        }.padding(.horizontal, 24)
                    }

                    Text("Specialty").font(.caption).foregroundColor(Color.nmaSecondary).padding(.horizontal, 24)
                    TextField("Specialty", text: $specialty).modifier(TextFieldModifier())

                    Text("Subspecialties").font(.caption).foregroundColor(Color.nmaSecondary).padding(.horizontal, 24)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(medSpecialties.filter { $0 != specialty }, id: \.self) { sub in
                                let sel = subspecialties.contains(sub)
                                Button {
                                    if sel { subspecialties.removeAll { $0 == sub } }
                                    else if subspecialties.count < 3 { subspecialties.append(sub) }
                                } label: {
                                    Text(sub).font(.subheadline)
                                        .foregroundColor(sel ? .white : Color.nmaSecondary)
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(sel ? Color.nmaPrimary : Color.nmaSubtle)
                                        .cornerRadius(20)
                                }
                            }
                        }.padding(.horizontal, 24)
                    }

                    Text("Board Certifications").font(.caption).foregroundColor(Color.nmaSecondary).padding(.horizontal, 24)
                    HStack(spacing: 8) {
                        TextField("Add certification", text: $newCert).font(.subheadline)
                            .foregroundColor(.nmaPrimary).padding(14)
                            .background(Color.nmaSurface).cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.nmaBorder, lineWidth: 0.5))
                        Button {
                            let c = newCert.trimmingCharacters(in: .whitespaces)
                            if !c.isEmpty { boardCertifications.append(c); newCert = "" }
                        } label: {
                            Image(systemName: "plus.circle.fill").foregroundColor(Color.nmaPrimary).font(.title3)
                        }
                    }.padding(.horizontal, 24)

                    ForEach(boardCertifications, id: \.self) { cert in
                        HStack {
                            Text(cert).font(.subheadline).foregroundColor(Color.nmaPrimary)
                            Spacer()
                            Button { boardCertifications.removeAll { $0 == cert } } label: {
                                Image(systemName: "xmark").font(.caption).foregroundColor(Color.nmaSecondary)
                            }
                        }.padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Specialty & Credentials")
        .navigationBarTitleDisplayMode(.inline)
        .saveStatus(saver)
        .onChange(of: degreeType) { saver.save(["degreeType": $0.rawValue]) }
        .onChange(of: specialty) { saver.save(["specialty": $0], after: .milliseconds(800)) }
        .onChange(of: subspecialties) { saver.save(["subspecialties": $0], after: .milliseconds(400)) }
        .onChange(of: boardCertifications) { saver.save(["boardCertifications": $0]) }
    }


    @ViewBuilder
    private func degreeChip(_ deg: DegreeType) -> some View {
        Button { degreeType = deg } label: {
            Text(deg.rawValue).font(.subheadline)
                .foregroundColor(degreeType == deg ? .white : Color.nmaSecondary)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(degreeType == deg ? Color.nmaPrimary : Color.nmaSubtle)
                .cornerRadius(20)
        }
    }
}

// MARK: - Edit Practice View

struct EditPracticeView: View {
    @State private var institution = UserService.shared.currentUser?.currentInstitution ?? ""
    @State private var practiceType = UserService.shared.currentUser?.practiceType ?? PracticeType.academic
    @State private var region = UserService.shared.currentUser?.locationRegion ?? ""
    @StateObject private var saver = AutoSaver()

    var body: some View {
        ZStack {
            Color.nmaBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Institution").font(.caption).foregroundColor(Color.nmaSecondary)
                        .padding(.horizontal, 24).padding(.top, 16)
                    TextField("Hospital or practice name", text: $institution).modifier(TextFieldModifier())

                    Text("Practice Type").font(.caption).foregroundColor(Color.nmaSecondary).padding(.horizontal, 24)
                    VStack(spacing: 0) {
                        ForEach(PracticeType.allCases, id: \.self) { pt in
                            Button { practiceType = pt } label: {
                                HStack {
                                    Text(pt.rawValue).font(.subheadline).foregroundColor(Color.nmaPrimary)
                                    Spacer()
                                    if practiceType == pt {
                                        Image(systemName: "checkmark").foregroundColor(Color.nmaPrimary).font(.subheadline)
                                    }
                                }
                                .padding(.horizontal, 16).padding(.vertical, 14)
                            }
                            if pt != PracticeType.allCases.last {
                                Divider().background(Color.nmaBorder)
                            }
                        }
                    }
                    .background(Color.nmaSurface).cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.nmaBorder, lineWidth: 0.5))
                    .padding(.horizontal, 24)

                    Text("Metro Area / Region").font(.caption).foregroundColor(Color.nmaSecondary).padding(.horizontal, 24)
                    TextField("e.g. New York, NY", text: $region).modifier(TextFieldModifier())
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Practice & Institution")
        .navigationBarTitleDisplayMode(.inline)
        .saveStatus(saver)
        .onChange(of: institution) { saver.save(["currentInstitution": $0], after: .milliseconds(800)) }
        .onChange(of: practiceType) { saver.save(["practiceType": $0.rawValue]) }
        .onChange(of: region) { saver.save(["locationRegion": $0], after: .milliseconds(800)) }
    }

}

// MARK: - Edit Licenses View

struct EditLicensesView: View {
    @State private var selected = UserService.shared.currentUser?.stateLicenses ?? []
    @StateObject private var saver = AutoSaver()

    var body: some View {
        ZStack {
            Color.nmaBackground.ignoresSafeArea()
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                    ForEach(usStates, id: \.self) { state in
                        let sel = selected.contains(state)
                        Button {
                            if sel { selected.removeAll { $0 == state } }
                            else { selected.append(state) }
                        } label: {
                            Text(state).font(.caption).fontWeight(.medium)
                                .foregroundColor(sel ? .white : Color.nmaSecondary)
                                .frame(maxWidth: .infinity).padding(.vertical, 8)
                                .background(sel ? Color.nmaPrimary : Color.nmaSubtle)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle("State Licenses")
        .navigationBarTitleDisplayMode(.inline)
        .saveStatus(saver)
        .onChange(of: selected) { saver.save(["stateLicenses": $0], after: .milliseconds(400)) }
    }

}

// MARK: - Edit Languages View

struct EditLanguagesView: View {
    @State private var selected = UserService.shared.currentUser?.languagesSpoken ?? ["English"]
    @StateObject private var saver = AutoSaver()

    var body: some View {
        ZStack {
            Color.nmaBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Languages Spoken").font(.caption).foregroundColor(Color.nmaSecondary)
                        .padding(.horizontal, 24).padding(.top, 16)
                    FlowTagGrid(items: spokenLanguages, selected: $selected).padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Languages")
        .navigationBarTitleDisplayMode(.inline)
        .saveStatus(saver)
        .onChange(of: selected) { saver.save(["languagesSpoken": $0], after: .milliseconds(400)) }
    }

}

private struct FlowTagGrid: View {
    let items: [String]
    @Binding var selected: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 10) {
            ForEach(items, id: \.self) { item in
                let sel = selected.contains(item)
                Button {
                    if sel { selected.removeAll { $0 == item } }
                    else { selected.append(item) }
                } label: {
                    Text(item).font(.subheadline)
                        .foregroundColor(sel ? .white : Color.nmaSecondary)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(sel ? Color.nmaPrimary : Color.nmaSubtle)
                        .cornerRadius(10)
                }
            }
        }
    }
}

// MARK: - Delete Confirmation

struct DeleteAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var showFinalConfirmation = false

    var body: some View {
        ZStack {
            Color.nmaBackground.ignoresSafeArea()
            VStack(spacing: 20) {
                Spacer()
                Text("Delete Account")
                    .font(.title3).fontWeight(.semibold).foregroundColor(Color.nmaPrimary)
                Text("This permanently deletes your profile and login. People you've messaged will see \"Deleted user\" in those conversations. This can't be undone.")
                    .font(.subheadline).foregroundColor(Color.nmaSecondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 32)

                SecureField("Enter your password to confirm", text: $password)
                    .textContentType(.password)
                    .modifier(TextFieldModifier())

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption).foregroundColor(.red)
                        .multilineTextAlignment(.center).padding(.horizontal, 32)
                }

                Button { showFinalConfirmation = true } label: {
                    Group {
                        if isDeleting { ProgressView().tint(.white) }
                        else { Text("Delete My Account").fontWeight(.semibold) }
                    }
                    .font(.subheadline).foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(password.isEmpty ? Color.red.opacity(0.4) : Color.red)
                    .cornerRadius(12).padding(.horizontal, 24)
                }
                .disabled(password.isEmpty || isDeleting)

                Button("Cancel") { dismiss() }
                    .font(.subheadline).foregroundColor(Color.nmaSecondary)
                    .disabled(isDeleting)
                Spacer()
            }
        }
        .interactiveDismissDisabled(isDeleting)
        .confirmationDialog("Delete your account permanently?",
                            isPresented: $showFinalConfirmation, titleVisibility: .visible) {
            Button("Delete Account", role: .destructive) { delete() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func delete() {
        errorMessage = nil
        isDeleting = true
        Task {
            do {
                // On success the app returns to the login screen, which confirms the deletion.
                try await AuthService.shared.deleteAccount(password: password)
            } catch {
                errorMessage = AuthService.friendlyMessage(for: error)
                isDeleting = false
            }
        }
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View { Settings() }
}
