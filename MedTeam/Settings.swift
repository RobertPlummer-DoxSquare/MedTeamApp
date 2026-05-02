//
//  Settings.swift
//  MedTeamApp
//
//  Created by Robert Plummer on 7/4/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine

// MARK: - SettingsViewModel

class SettingsViewModel: ObservableObject {
    @Published var acceptingReferrals = false
    @Published var openToCollaboration = false
    @Published var isMentor = false
    @Published var user: User?

    private var cancellables = Set<AnyCancellable>()

    init() {
        UserService.shared.$currentUser
            .receive(on: RunLoop.main)
            .sink { [weak self] user in
                self?.user = user
                self?.acceptingReferrals = user?.isAcceptingReferrals ?? false
                self?.openToCollaboration = user?.isOpenToCollaboration ?? false
                self?.isMentor = user?.isMentor ?? false
            }
            .store(in: &cancellables)
    }

    func updateField(_ field: String, value: Any) {
        UserService.shared.updateField(field, value: value)
    }
}

// MARK: - Settings

struct Settings: View {
    @StateObject var viewModel = SettingsViewModel()
    @State private var showDeleteConfirmation = false
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationView {
            List {
                // Profile
                Section("Profile") {
                    NavigationLink("Specialty & Credentials") { EditSpecialtyView() }
                    NavigationLink("Practice & Institution")  { EditPracticeView() }
                    NavigationLink("State Licenses")          { EditLicensesView() }
                    NavigationLink("Languages")               { EditLanguagesView() }
                }

                // Networking
                Section("Networking") {
                    Toggle("Accepting Referrals", isOn: $viewModel.acceptingReferrals)
                        .onChange(of: viewModel.acceptingReferrals) {
                            viewModel.updateField("isAcceptingReferrals", value: viewModel.acceptingReferrals)
                        }
                    Toggle("Open to Collaboration", isOn: $viewModel.openToCollaboration)
                        .onChange(of: viewModel.openToCollaboration) {
                            viewModel.updateField("isOpenToCollaboration", value: viewModel.openToCollaboration)
                        }
                    Toggle("Available as Mentor", isOn: $viewModel.isMentor)
                        .onChange(of: viewModel.isMentor) {
                            viewModel.updateField("isMentor", value: viewModel.isMentor)
                        }
                }

                // Verification
                Section("Verification") {
                    NavigationLink {
                        NPIVerificationView()
                    } label: {
                        HStack {
                            Text("NPI Verification")
                            Spacer()
                            if viewModel.user?.npiVerified == true {
                                Label("Verified", systemImage: "checkmark.seal.fill")
                                    .font(.caption).foregroundColor(.green)
                            }
                        }
                    }
                }

                // Account
                Section("Account") {
                    Button("Log Out", role: .destructive) {
                        AuthService.shared.signOut()
                    }
                    Button("Delete Account", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .colorScheme(.dark)
            .sheet(isPresented: $showDeleteConfirmation) {
                ConfirmationView { deleteAccount() }
            }
            .alert("Account Deleted", isPresented: $showDeleteAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func deleteAccount() {
        showDeleteAlert = true
    }
}

// MARK: - NPI Verification View

struct NPIVerificationView: View {
    @State private var npiInput = UserService.shared.currentUser?.npiNumber ?? ""
    @State private var lookupState: LookupState = .idle
    @State private var result: NPIResult?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Enter your 10-digit NPI to verify your identity.")
                        .font(.subheadline).foregroundColor(Color(white: 0.5))
                        .padding(.horizontal, 24).padding(.top, 16)

                    TextField("NPI Number", text: $npiInput)
                        .keyboardType(.numberPad)
                        .modifier(TextFieldModifier())

                    switch lookupState {
                    case .success:
                        if let r = result {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(r.fullName).font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                                    Text(r.specialty).font(.caption).foregroundColor(Color(white: 0.5))
                                }
                            }
                            .padding(14).background(Color(white: 0.08)).cornerRadius(12)
                            .padding(.horizontal, 24)
                        }
                    case .failure(let msg):
                        Text(msg).font(.caption).foregroundColor(.red).padding(.horizontal, 24)
                    default: EmptyView()
                    }

                    Button {
                        Task {
                            lookupState = .loading
                            do {
                                result = try await NPIService.lookup(npi: npiInput)
                                let uid = Auth.auth().currentUser?.uid ?? ""
                                try await Firestore.firestore().collection("users").document(uid)
                                    .updateData(["npiNumber": npiInput, "npiVerified": true])
                                try await UserService.shared.fetchCurrentUser()
                                lookupState = .success
                            } catch {
                                lookupState = .failure(error.localizedDescription)
                            }
                        }
                    } label: {
                        Group {
                            if lookupState == .loading { ProgressView().tint(.black) }
                            else { Text("Verify NPI").font(.subheadline).fontWeight(.semibold).foregroundColor(.black) }
                        }
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Color.white).cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .disabled(lookupState == .loading)
                }
            }
        }
        .navigationTitle("NPI Verification")
        .navigationBarTitleDisplayMode(.inline)
        .colorScheme(.dark)
    }
}

// MARK: - Edit Specialty View

struct EditSpecialtyView: View {
    @State private var specialty = UserService.shared.currentUser?.specialty ?? ""
    @State private var degreeType = UserService.shared.currentUser?.degreeType ?? .md
    @State private var subspecialties = UserService.shared.currentUser?.subspecialties ?? []
    @State private var boardCertifications = UserService.shared.currentUser?.boardCertifications ?? []
    @State private var newCert = ""
    @State private var isSaving = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Degree").font(.caption).foregroundColor(Color(white: 0.4)).padding(.horizontal, 24).padding(.top, 16)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(DegreeType.allCases, id: \.self) { deg in
                                degreeChip(deg)
                            }
                        }.padding(.horizontal, 24)
                    }

                    Text("Specialty").font(.caption).foregroundColor(Color(white: 0.4)).padding(.horizontal, 24)
                    TextField("Specialty", text: $specialty).modifier(TextFieldModifier())

                    Text("Subspecialties").font(.caption).foregroundColor(Color(white: 0.4)).padding(.horizontal, 24)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(medSpecialties.filter { $0 != specialty }, id: \.self) { sub in
                                let sel = subspecialties.contains(sub)
                                Button {
                                    if sel { subspecialties.removeAll { $0 == sub } }
                                    else if subspecialties.count < 3 { subspecialties.append(sub) }
                                } label: {
                                    Text(sub).font(.subheadline)
                                        .foregroundColor(sel ? .black : Color(white: 0.7))
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(sel ? Color.white : Color(white: 0.12))
                                        .cornerRadius(20)
                                }
                            }
                        }.padding(.horizontal, 24)
                    }

                    Text("Board Certifications").font(.caption).foregroundColor(Color(white: 0.4)).padding(.horizontal, 24)
                    HStack(spacing: 8) {
                        TextField("Add certification", text: $newCert).font(.subheadline).padding(14)
                            .background(Color(white: 0.1)).cornerRadius(12)
                        Button {
                            let c = newCert.trimmingCharacters(in: .whitespaces)
                            if !c.isEmpty { boardCertifications.append(c); newCert = "" }
                        } label: {
                            Image(systemName: "plus.circle.fill").foregroundColor(.white).font(.title3)
                        }
                    }.padding(.horizontal, 24)

                    ForEach(boardCertifications, id: \.self) { cert in
                        HStack {
                            Text(cert).font(.subheadline).foregroundColor(.white)
                            Spacer()
                            Button { boardCertifications.removeAll { $0 == cert } } label: {
                                Image(systemName: "xmark").font(.caption).foregroundColor(Color(white: 0.4))
                            }
                        }.padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Specialty & Credentials")
        .navigationBarTitleDisplayMode(.inline)
        .colorScheme(.dark)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await save() }
                } label: {
                    if isSaving { ProgressView().tint(.white) }
                    else { Text("Done").fontWeight(.semibold) }
                }
                .disabled(isSaving)
            }
        }
    }

    @MainActor
    private func save() async {
        isSaving = true
        guard let uid = Auth.auth().currentUser?.uid else { isSaving = false; return }
        try? await Firestore.firestore().collection("users").document(uid).updateData([
            "degreeType": degreeType.rawValue,
            "specialty": specialty,
            "subspecialties": subspecialties,
            "boardCertifications": boardCertifications
        ])
        try? await UserService.shared.fetchCurrentUser()
        isSaving = false
        dismiss()
    }

    @ViewBuilder
    private func degreeChip(_ deg: DegreeType) -> some View {
        Button { degreeType = deg } label: {
            Text(deg.rawValue).font(.subheadline)
                .foregroundColor(degreeType == deg ? .black : Color(white: 0.7))
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(degreeType == deg ? Color.white : Color(white: 0.12))
                .cornerRadius(20)
        }
    }
}

// MARK: - Edit Practice View

struct EditPracticeView: View {
    @State private var institution = UserService.shared.currentUser?.currentInstitution ?? ""
    @State private var practiceType = UserService.shared.currentUser?.practiceType ?? PracticeType.academic
    @State private var region = UserService.shared.currentUser?.locationRegion ?? ""
    @State private var isSaving = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Institution").font(.caption).foregroundColor(Color(white: 0.4)).padding(.horizontal, 24).padding(.top, 16)
                    TextField("Hospital or practice name", text: $institution).modifier(TextFieldModifier())

                    Text("Practice Type").font(.caption).foregroundColor(Color(white: 0.4)).padding(.horizontal, 24)
                    VStack(spacing: 0) {
                        ForEach(PracticeType.allCases, id: \.self) { pt in
                            Button { practiceType = pt } label: {
                                HStack {
                                    Text(pt.rawValue).font(.subheadline).foregroundColor(.white)
                                    Spacer()
                                    if practiceType == pt {
                                        Image(systemName: "checkmark").foregroundColor(.blue).font(.subheadline)
                                    }
                                }
                                .padding(.horizontal, 16).padding(.vertical, 14)
                            }
                            if pt != PracticeType.allCases.last {
                                Divider().background(Color(white: 0.12))
                            }
                        }
                    }
                    .background(Color(white: 0.08)).cornerRadius(12).padding(.horizontal, 24)

                    Text("Metro Area / Region").font(.caption).foregroundColor(Color(white: 0.4)).padding(.horizontal, 24)
                    TextField("e.g. New York, NY", text: $region).modifier(TextFieldModifier())
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Practice & Institution")
        .navigationBarTitleDisplayMode(.inline)
        .colorScheme(.dark)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await save() }
                } label: {
                    if isSaving { ProgressView().tint(.white) }
                    else { Text("Done").fontWeight(.semibold) }
                }
                .disabled(isSaving)
            }
        }
    }

    @MainActor
    private func save() async {
        isSaving = true
        guard let uid = Auth.auth().currentUser?.uid else { isSaving = false; return }
        try? await Firestore.firestore().collection("users").document(uid).updateData([
            "currentInstitution": institution,
            "practiceType": practiceType.rawValue,
            "locationRegion": region
        ])
        try? await UserService.shared.fetchCurrentUser()
        isSaving = false
        dismiss()
    }
}

// MARK: - Edit Licenses View

struct EditLicensesView: View {
    @State private var selected = UserService.shared.currentUser?.stateLicenses ?? []
    @State private var isSaving = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                    ForEach(usStates, id: \.self) { state in
                        let sel = selected.contains(state)
                        Button {
                            if sel { selected.removeAll { $0 == state } }
                            else { selected.append(state) }
                        } label: {
                            Text(state).font(.caption).fontWeight(.medium)
                                .foregroundColor(sel ? .black : Color(white: 0.6))
                                .frame(maxWidth: .infinity).padding(.vertical, 8)
                                .background(sel ? Color.white : Color(white: 0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle("State Licenses")
        .navigationBarTitleDisplayMode(.inline)
        .colorScheme(.dark)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await save() }
                } label: {
                    if isSaving { ProgressView().tint(.white) }
                    else { Text("Done").fontWeight(.semibold) }
                }
                .disabled(isSaving)
            }
        }
    }

    @MainActor
    private func save() async {
        isSaving = true
        guard let uid = Auth.auth().currentUser?.uid else { isSaving = false; return }
        try? await Firestore.firestore().collection("users").document(uid).updateData([
            "stateLicenses": selected
        ])
        try? await UserService.shared.fetchCurrentUser()
        isSaving = false
        dismiss()
    }
}

// MARK: - Edit Languages View

struct EditLanguagesView: View {
    @State private var selected = UserService.shared.currentUser?.languagesSpoken ?? ["English"]
    @State private var isSaving = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Languages Spoken")
                        .font(.caption).foregroundColor(Color(white: 0.4))
                        .padding(.horizontal, 24).padding(.top, 16)

                    FlowTagGrid(items: spokenLanguages, selected: $selected)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Languages")
        .navigationBarTitleDisplayMode(.inline)
        .colorScheme(.dark)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await save() }
                } label: {
                    if isSaving { ProgressView().tint(.white) }
                    else { Text("Done").fontWeight(.semibold) }
                }
                .disabled(isSaving)
            }
        }
    }

    @MainActor
    private func save() async {
        isSaving = true
        guard let uid = Auth.auth().currentUser?.uid else { isSaving = false; return }
        try? await Firestore.firestore().collection("users").document(uid).updateData([
            "languagesSpoken": selected
        ])
        try? await UserService.shared.fetchCurrentUser()
        isSaving = false
        dismiss()
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
                        .foregroundColor(sel ? .black : Color(white: 0.7))
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(sel ? Color.white : Color(white: 0.12))
                        .cornerRadius(10)
                }
            }
        }
    }
}

// MARK: - Delete Confirmation

struct ConfirmationView: View {
    let confirmAction: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                Text("Delete Account")
                    .font(.title3).fontWeight(.semibold).foregroundColor(.white)
                Text("This action is permanent and cannot be undone.")
                    .font(.subheadline).foregroundColor(Color(white: 0.45))
                    .multilineTextAlignment(.center).padding(.horizontal, 40)
                Button(action: confirmAction) {
                    Text("Delete My Account")
                        .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Color.red).cornerRadius(12)
                        .padding(.horizontal, 24)
                }
                Spacer()
            }
        }
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings()
    }
}
