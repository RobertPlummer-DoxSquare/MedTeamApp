//
//  OnboardingView.swift
//  MedTeam
//

import SwiftUI

// MARK: - Constants

let medSpecialties = [
    "Anesthesiology", "Cardiology", "Dermatology", "Emergency Medicine",
    "Endocrinology", "Family Medicine", "Gastroenterology", "General Surgery",
    "Geriatrics", "Hematology/Oncology", "Hospitalist", "Infectious Disease",
    "Internal Medicine", "Nephrology", "Neurology", "Neurosurgery", "OB/GYN",
    "Ophthalmology", "Orthopedic Surgery", "Otolaryngology", "Pathology",
    "Pediatrics", "Plastic Surgery", "Psychiatry", "Pulmonology / Critical Care",
    "Radiology", "Rheumatology", "Urology", "Vascular Surgery"
]

let usStates = [
    "AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
    "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
    "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
    "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
    "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"
]

let spokenLanguages = [
    "English","Spanish","Mandarin","Hindi","French",
    "Arabic","Portuguese","Russian","Japanese","Korean","Other"
]

// MARK: - Container

struct OnboardingView: View {
    @StateObject private var vm = OnboardingViewModel()
    @State private var step = 1
    private let totalSteps = 3

    var body: some View {
        ZStack {
            Color.nmaBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    ProgressView(value: Double(step), total: Double(totalSteps))
                        .tint(Color.nmaPrimary)
                        .accessibilityLabel("Step \(step) of \(totalSteps)")
                    Button("Log out") { AuthService.shared.signOut() }
                        .font(.subheadline)
                        .foregroundColor(Color.nmaSecondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Group {
                    switch step {
                    case 1: MemberTypeStep(vm: vm, onNext: { step = 2 })
                    case 2: VerifyStep(vm: vm, onNext: { step = 3 }, onBack: { step = 1 })
                    default: BasicsStep(vm: vm, onBack: { step = 2 })
                    }
                }
                .animation(.easeInOut(duration: 0.22), value: step)
            }
        }
    }
}

// MARK: - Shared Components

private struct OnboardingHeader: View {
    let step: Int
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Step \(step) of 3")
                .font(.caption).foregroundColor(Color.nmaSecondary)
            Text(title)
                .font(.title2).fontWeight(.semibold).foregroundColor(Color.nmaPrimary)
            Text(subtitle)
                .font(.subheadline).foregroundColor(Color.nmaSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }
}

private struct PrimaryButton: View {
    let title: String
    let loading: Bool
    let enabled: Bool
    let action: () -> Void

    init(_ title: String, loading: Bool = false, enabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.loading = loading
        self.enabled = enabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Group {
                if loading { ProgressView().tint(.white) }
                else { Text(title).font(.subheadline).fontWeight(.semibold).foregroundColor(.white) }
            }
            .frame(maxWidth: .infinity).frame(height: 50)
            .background(Color.nmaPrimary.opacity(enabled ? 1 : 0.4)).cornerRadius(12)
        }
        .padding(.horizontal, 24)
        .disabled(loading || !enabled)
    }
}

private struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title).font(.subheadline).foregroundColor(Color.nmaSecondary)
        }
    }
}

private func fieldLabel(_ text: String) -> some View {
    Text(text).font(.caption).foregroundColor(Color.nmaSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
}

// MARK: - Screen 1: I am a…

struct MemberTypeStep: View {
    @ObservedObject var vm: OnboardingViewModel
    let onNext: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                OnboardingHeader(step: 1, title: "I am a…",
                                 subtitle: "This helps members know how to connect with you.")
                typeCard(.clinician, icon: "stethoscope",
                         detail: "Physician or other licensed clinician. Verify with your NPI.")
                typeCard(.student, icon: "graduationcap",
                         detail: "Medical or health professions student. Verify with your school email.")
                Spacer().frame(height: 20)
                PrimaryButton("Continue", action: onNext)
                    .padding(.bottom, 40)
            }
        }
    }

    private func typeCard(_ type: MemberType, icon: String, detail: String) -> some View {
        let selected = vm.memberType == type
        return Button { vm.memberType = type } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(selected ? .white : Color.nmaPrimary)
                    .frame(width: 44, height: 44)
                    .background(selected ? Color.nmaPrimary : Color.nmaSubtle)
                    .cornerRadius(10)
                VStack(alignment: .leading, spacing: 3) {
                    Text(type.displayName).font(.headline).foregroundColor(Color.nmaPrimary)
                    Text(detail).font(.caption).foregroundColor(Color.nmaSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selected ? Color.nmaPrimary : Color.nmaBorder)
            }
            .padding(14)
            .background(Color.nmaSurface)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(selected ? Color.nmaPrimary : Color.nmaBorder, lineWidth: selected ? 1 : 0.5))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

// MARK: - Screen 2: Verify

struct VerifyStep: View {
    @ObservedObject var vm: OnboardingViewModel
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if vm.memberType == .clinician {
                    OnboardingHeader(step: 2, title: "Verify your NPI",
                                     subtitle: "Your 10-digit NPI is public record. A match earns the Verified clinician badge.")
                    npiSection
                } else {
                    OnboardingHeader(step: 2, title: "Verify your school email",
                                     subtitle: "We'll send a confirmation link to your .edu address. A confirmed email earns the Verified student badge.")
                    schoolSection
                }

                Spacer().frame(height: 12)
                VStack(spacing: 14) {
                    PrimaryButton("Continue", enabled: isVerifiedOrSent, action: onNext)
                    SecondaryButton(title: "Verify later", action: onNext)
                    SecondaryButton(title: "Back", action: onBack)
                }
                .padding(.bottom, 40)
            }
        }
    }

    private var isVerifiedOrSent: Bool {
        vm.memberType == .clinician ? vm.lookupState == .success : vm.schoolEmailSent
    }

    @ViewBuilder
    private var npiSection: some View {
        TextField("NPI Number", text: $vm.npiNumber)
            .keyboardType(.numberPad)
            .modifier(TextFieldModifier())

        switch vm.lookupState {
        case .success:
            if let r = vm.npiResult {
                HStack(spacing: 12) {
                    Image(systemName: vm.npiNameMatches ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(vm.npiNameMatches ? .referralGreen : .pendingAmber)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(r.fullName).font(.subheadline).fontWeight(.semibold).foregroundColor(Color.nmaPrimary)
                        if !r.specialty.isEmpty {
                            Text(r.specialty).font(.caption).foregroundColor(Color.nmaSecondary)
                        }
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color.nmaSurface)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.nmaBorder, lineWidth: 0.5))
                .padding(.horizontal, 24)

                if !vm.npiNameMatches {
                    NPINameMismatchNote(registryName: r.fullName)
                }
            }
        case .failure(let msg):
            Text(msg).font(.caption).foregroundColor(.red).padding(.horizontal, 24)
        default:
            EmptyView()
        }

        Button {
            Task { await vm.lookupNPI() }
        } label: {
            Group {
                if vm.lookupState == .loading { ProgressView().tint(Color.nmaPrimary) }
                else { Text("Look Up NPI").font(.subheadline).fontWeight(.semibold) }
            }
            .foregroundColor(Color.nmaPrimary)
            .frame(maxWidth: .infinity).frame(height: 44)
            .background(Color.nmaSubtle).cornerRadius(12)
        }
        .padding(.horizontal, 24)
        .disabled(vm.npiNumber.count != 10 || vm.lookupState == .loading)
    }

    @ViewBuilder
    private var schoolSection: some View {
        TextField("you@school.edu", text: $vm.schoolEmail)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .modifier(TextFieldModifier())

        if case .failure(let msg) = vm.schoolEmailState {
            Text(msg).font(.caption).foregroundColor(.red).padding(.horizontal, 24)
        }

        if vm.schoolEmailSent {
            Label("Link sent to \(vm.schoolEmail). Open it on any device. Your Verified student badge appears once it's confirmed; you can keep going.",
                  systemImage: "envelope.badge")
                .font(.caption).foregroundColor(Color.nmaSecondary)
                .padding(.horizontal, 24)
        }

        Button {
            Task { await vm.sendSchoolVerification() }
        } label: {
            Group {
                if vm.schoolEmailState == .loading { ProgressView().tint(Color.nmaPrimary) }
                else { Text(vm.schoolEmailSent ? "Resend Link" : "Send Confirmation Link").font(.subheadline).fontWeight(.semibold) }
            }
            .foregroundColor(Color.nmaPrimary)
            .frame(maxWidth: .infinity).frame(height: 44)
            .background(Color.nmaSubtle).cornerRadius(12)
        }
        .padding(.horizontal, 24)
        .disabled(vm.schoolEmail.isEmpty || vm.schoolEmailState == .loading)
    }
}

// MARK: - Screen 3: Basics

struct BasicsStep: View {
    @ObservedObject var vm: OnboardingViewModel
    let onBack: () -> Void
    @State private var showSpecialtyPicker = false
    @State private var specialtySearch = ""

    private var isStudent: Bool { vm.memberType == .student }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                OnboardingHeader(step: 3, title: "The basics",
                                 subtitle: "You can change any of this later in Settings.")

                fieldLabel(isStudent ? "Program and year" : "Credentials")
                TextField(isStudent ? "e.g. MD candidate, class of 2028" : "e.g. MD, FACS", text: $vm.credentials)
                    .modifier(TextFieldModifier())

                fieldLabel(isStudent ? "Intended specialty" : "Specialty")
                Button { showSpecialtyPicker = true } label: {
                    HStack {
                        Text(vm.specialty.isEmpty ? "Choose a specialty" : vm.specialty)
                            .foregroundColor(vm.specialty.isEmpty ? Color.nmaSecondary : Color.nmaPrimary)
                        Spacer()
                        Image(systemName: "chevron.down").font(.caption).foregroundColor(Color.nmaSecondary)
                    }
                    .font(.subheadline)
                    .padding(14)
                    .background(Color.nmaSurface).cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.nmaBorder, lineWidth: 0.5))
                }
                .padding(.horizontal, 24)

                fieldLabel(isStudent ? "School" : "Institution or practice")
                TextField(isStudent ? "e.g. Howard University College of Medicine" : "Hospital or practice name",
                          text: $vm.institution)
                    .modifier(TextFieldModifier())

                fieldLabel("NMA region")
                VStack(spacing: 8) {
                    ForEach(regionsInOrder, id: \.self) { region in
                        RegionOptionCard(region: region, isSelected: vm.nmaRegion == region) {
                            vm.nmaRegion = region
                        }
                    }
                }
                .padding(.horizontal, 24)

                fieldLabel("Availability")
                VStack(spacing: 0) {
                    availabilityToggle("Open to mentoring", isOn: $vm.isMentor)
                    Divider()
                    availabilityToggle("Open to collaboration", isOn: $vm.isOpenToCollaboration)
                    if !isStudent {
                        Divider()
                        availabilityToggle("Accepting referrals", isOn: $vm.isOpenToReferrals)
                        if vm.isOpenToReferrals {
                            Divider()
                            TextField("Office phone (required for referrals)", text: $vm.officePhone)
                                .keyboardType(.phonePad)
                                .font(.subheadline)
                                .foregroundColor(Color.nmaPrimary)
                                .padding(.horizontal, 16).padding(.vertical, 12)
                        }
                    }
                }
                .background(Color.nmaSurface)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.nmaBorder, lineWidth: 0.5))
                .padding(.horizontal, 24)

                if let error = vm.saveError {
                    Text(error).font(.caption).foregroundColor(.red).padding(.horizontal, 24)
                }

                Spacer().frame(height: 12)
                VStack(spacing: 14) {
                    PrimaryButton("Finish", loading: vm.isSaving, enabled: vm.canFinish) {
                        Task { await vm.save() }
                    }
                    if !vm.canFinish {
                        Text("Add a specialty and \(isStudent ? "school" : "institution") to finish.")
                            .font(.caption).foregroundColor(Color.nmaSecondary)
                    }
                    SecondaryButton(title: "Back", action: onBack)
                }
                .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: $showSpecialtyPicker) {
            SpecialtyPickerSheet(selected: $vm.specialty, search: $specialtySearch)
        }
    }

    private var regionsInOrder: [NMARegion] {
        guard let suggested = vm.suggestedRegion else { return NMARegion.allCases }
        return [suggested] + NMARegion.allCases.filter { $0 != suggested }
    }

    private func availabilityToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .font(.subheadline)
            .foregroundColor(Color.nmaPrimary)
            .tint(Color.nmaPrimary)
            .padding(.horizontal, 16).padding(.vertical, 10)
    }
}

private struct SpecialtyPickerSheet: View {
    @Binding var selected: String
    @Binding var search: String
    @Environment(\.dismiss) var dismiss

    var filtered: [String] {
        search.isEmpty ? medSpecialties : medSpecialties.filter { $0.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List(filtered, id: \.self) { spec in
                Button {
                    selected = spec; dismiss()
                } label: {
                    HStack {
                        Text(spec).foregroundColor(Color.nmaPrimary)
                        Spacer()
                        if selected == spec {
                            Image(systemName: "checkmark").foregroundColor(Color.nmaPrimary)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $search, prompt: "Search specialties")
            .navigationTitle("Specialty")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }
}

private struct RegionOptionCard: View {
    let region: NMARegion
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(region.displayName)
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(isSelected ? region.badgeForeground : Color.nmaPrimary)
                        Text(region.statesDisplay)
                            .font(.caption).foregroundColor(Color.nmaSecondary)
                            .lineLimit(1)
                    }
                    Text("Chair: \(region.chairName)")
                        .font(.caption).foregroundColor(Color.nmaSecondary)
                    if region.nextMeeting != "TBD" {
                        Text(region.nextMeeting)
                            .font(.caption2).foregroundColor(Color.nmaSecondary.opacity(0.7))
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(region.badgeForeground)
                }
            }
            .padding(14)
            .background(isSelected ? region.badgeBackground : Color.nmaSurface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? region.badgeForeground.opacity(0.3) : Color.nmaBorder, lineWidth: 0.5)
            )
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View { OnboardingView() }
}
