//
//  OnboardingView.swift
//  MedTeam
//

import SwiftUI

// MARK: - Constants (accessible app-wide within the module)

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

// MARK: - Onboarding Container

struct OnboardingView: View {
    @StateObject private var vm = OnboardingViewModel()
    @State private var step = 1
    private let totalSteps = 5

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 4)

                Group {
                    switch step {
                    case 1: OnboardingStep1NPI(vm: vm, onNext: { step = 2 })
                    case 2: OnboardingStep2Credentials(vm: vm, onNext: { step = 3 }, onBack: { step = 1 })
                    case 3: OnboardingStep3Training(vm: vm, onNext: { step = 4 }, onBack: { step = 2 })
                    case 4: OnboardingStep4Practice(vm: vm, onNext: { step = 5 }, onBack: { step = 3 })
                    case 5: OnboardingStep5Networking(vm: vm, onBack: { step = 4 })
                    default: EmptyView()
                    }
                }
                .animation(.easeInOut(duration: 0.22), value: step)
            }
        }
        .colorScheme(.dark)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(white: 0.15)).frame(height: 3)
                Capsule().fill(Color.white)
                    .frame(width: geo.size.width * CGFloat(step) / CGFloat(totalSteps), height: 3)
                    .animation(.easeInOut, value: step)
            }
        }
        .frame(height: 3)
    }
}

// MARK: - Shared Components

private struct OnboardingHeader: View {
    let step: Int
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Step \(step) of 5")
                .font(.caption)
                .foregroundColor(Color(white: 0.4))
            Text(title)
                .font(.title2).fontWeight(.semibold).foregroundColor(.white)
            Text(subtitle)
                .font(.subheadline).foregroundColor(Color(white: 0.45))
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
    let action: () -> Void

    init(_ title: String, loading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.loading = loading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Group {
                if loading { ProgressView().tint(.black) }
                else { Text(title).font(.subheadline).fontWeight(.semibold).foregroundColor(.black) }
            }
            .frame(maxWidth: .infinity).frame(height: 50)
            .background(Color.white).cornerRadius(12)
        }
        .padding(.horizontal, 24)
        .disabled(loading)
    }
}

private struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title).font(.subheadline).foregroundColor(Color(white: 0.45))
        }
    }
}

private struct ChipToggle: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(selected ? .black : Color(white: 0.7))
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(selected ? Color.white : Color(white: 0.12))
                .cornerRadius(20)
        }
    }
}

// MARK: - Step 1: NPI Lookup

struct OnboardingStep1NPI: View {
    @ObservedObject var vm: OnboardingViewModel
    let onNext: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                OnboardingHeader(
                    step: 1,
                    title: "Verify Your Identity",
                    subtitle: "Your 10-digit NPI is public record. We use it to auto-fill your profile."
                )

                VStack(spacing: 16) {
                    TextField("NPI Number", text: $vm.npiNumber)
                        .keyboardType(.numberPad)
                        .modifier(TextFieldModifier())

                    switch vm.lookupState {
                    case .success:
                        if let r = vm.npiResult {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(r.fullName)
                                        .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                                    if !r.specialty.isEmpty {
                                        Text(r.specialty).font(.caption).foregroundColor(Color(white: 0.5))
                                    }
                                    if let org = r.organizationName {
                                        Text(org).font(.caption).foregroundColor(Color(white: 0.5))
                                    }
                                }
                                Spacer()
                            }
                            .padding(14)
                            .background(Color(white: 0.08))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }
                    case .failure(let msg):
                        Text(msg)
                            .font(.caption).foregroundColor(.red)
                            .padding(.horizontal, 24)
                    default:
                        EmptyView()
                    }

                    PrimaryButton(
                        "Look Up NPI",
                        loading: vm.lookupState == .loading
                    ) {
                        Task { await vm.lookupNPI() }
                    }

                    Divider().background(Color(white: 0.12)).padding(.horizontal, 24)

                    SecondaryButton(title: "Skip for now — enter manually") { onNext() }
                }
                .padding(.bottom, 40)

                if vm.lookupState == .success {
                    PrimaryButton("Continue") { onNext() }
                        .padding(.bottom, 32)
                }
            }
        }
    }
}

// MARK: - Step 2: Credentials & Specialty

struct OnboardingStep2Credentials: View {
    @ObservedObject var vm: OnboardingViewModel
    let onNext: () -> Void
    let onBack: () -> Void
    @State private var specialtySearch = ""
    @State private var showSpecialtyPicker = false

    var filteredSpecialties: [String] {
        specialtySearch.isEmpty ? medSpecialties :
            medSpecialties.filter { $0.localizedCaseInsensitiveContains(specialtySearch) }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                OnboardingHeader(
                    step: 2,
                    title: "Credentials & Specialty",
                    subtitle: "Help colleagues understand your background."
                )

                VStack(alignment: .leading, spacing: 20) {
                    // Degree Type
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Degree").font(.caption).foregroundColor(Color(white: 0.4)).padding(.horizontal, 24)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(DegreeType.allCases, id: \.self) { deg in
                                    ChipToggle(label: deg.rawValue, selected: vm.degreeType == deg) {
                                        vm.degreeType = deg
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }

                    // Specialty
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Specialty").font(.caption).foregroundColor(Color(white: 0.4)).padding(.horizontal, 24)
                        Button { showSpecialtyPicker = true } label: {
                            HStack {
                                Text(vm.specialty.isEmpty ? "Select specialty" : vm.specialty)
                                    .foregroundColor(vm.specialty.isEmpty ? Color(white: 0.4) : .white)
                                    .font(.subheadline)
                                Spacer()
                                Image(systemName: "chevron.down").foregroundColor(Color(white: 0.4)).font(.caption)
                            }
                            .padding(14)
                            .background(Color(white: 0.1))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }
                    }

                    // Subspecialties (max 3)
                    if !vm.specialty.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Subspecialties (max 3)").font(.caption).foregroundColor(Color(white: 0.4)).padding(.horizontal, 24)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(medSpecialties.filter { $0 != vm.specialty }, id: \.self) { sub in
                                        let selected = vm.subspecialties.contains(sub)
                                        ChipToggle(label: sub, selected: selected) {
                                            if selected {
                                                vm.subspecialties.removeAll { $0 == sub }
                                            } else if vm.subspecialties.count < 3 {
                                                vm.subspecialties.append(sub)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }

                    // Board Certifications
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Board Certifications").font(.caption).foregroundColor(Color(white: 0.4)).padding(.horizontal, 24)
                        HStack(spacing: 8) {
                            TextField("e.g. ABIM – Internal Medicine", text: $vm.newCertification)
                                .font(.subheadline)
                                .padding(14)
                                .background(Color(white: 0.1))
                                .cornerRadius(12)
                            Button {
                                let cert = vm.newCertification.trimmingCharacters(in: .whitespaces)
                                if !cert.isEmpty { vm.boardCertifications.append(cert); vm.newCertification = "" }
                            } label: {
                                Image(systemName: "plus.circle.fill").foregroundColor(.white).font(.title3)
                            }
                        }
                        .padding(.horizontal, 24)

                        ForEach(vm.boardCertifications, id: \.self) { cert in
                            HStack {
                                Text(cert).font(.subheadline).foregroundColor(.white)
                                Spacer()
                                Button { vm.boardCertifications.removeAll { $0 == cert } } label: {
                                    Image(systemName: "xmark").font(.caption).foregroundColor(Color(white: 0.4))
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 4)
                        }
                    }
                }

                Spacer().frame(height: 32)

                VStack(spacing: 12) {
                    PrimaryButton("Continue") { onNext() }
                    SecondaryButton(title: "Back") { onBack() }
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showSpecialtyPicker) {
            SpecialtyPickerSheet(selected: $vm.specialty, search: $specialtySearch)
        }
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
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                List(filtered, id: \.self) { spec in
                    Button {
                        selected = spec
                        dismiss()
                    } label: {
                        HStack {
                            Text(spec).foregroundColor(.white)
                            Spacer()
                            if selected == spec { Image(systemName: "checkmark").foregroundColor(.blue) }
                        }
                    }
                    .listRowBackground(Color(white: 0.08))
                }
                .listStyle(.plain)
                .searchable(text: $search, prompt: "Search specialties")
            }
            .navigationTitle("Specialty")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .colorScheme(.dark)
        }
    }
}

// MARK: - Step 3: Training History

struct OnboardingStep3Training: View {
    @ObservedObject var vm: OnboardingViewModel
    let onNext: () -> Void
    let onBack: () -> Void

    private let yearRange = Array((1950...OnboardingViewModel.thisYear).reversed())

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                OnboardingHeader(
                    step: 3,
                    title: "Training History",
                    subtitle: "Helps with mentorship matching and finding program colleagues."
                )

                VStack(alignment: .leading, spacing: 20) {
                    // Medical School
                    sectionLabel("Medical School")
                    TextField("Institution name", text: $vm.medicalSchool).modifier(TextFieldModifier())
                    yearPicker("Graduation Year", selection: $vm.medicalSchoolGradYear, years: yearRange)

                    Divider().background(Color(white: 0.12)).padding(.horizontal, 24)

                    // Residency
                    sectionLabel("Residency")
                    TextField("Program name", text: $vm.residencyProgram).modifier(TextFieldModifier())
                    yearPicker("Completion Year", selection: $vm.residencyCompletionYear, years: yearRange)

                    Divider().background(Color(white: 0.12)).padding(.horizontal, 24)

                    // Fellowship
                    HStack {
                        sectionLabel("Fellowship")
                        Spacer()
                        Toggle("", isOn: $vm.hasFellowship).labelsHidden().tint(.blue)
                    }
                    .padding(.horizontal, 24)

                    if vm.hasFellowship {
                        TextField("Program name", text: $vm.fellowshipProgram).modifier(TextFieldModifier())
                        yearPicker("Completion Year", selection: $vm.fellowshipCompletionYear, years: yearRange)
                    }
                }

                Spacer().frame(height: 32)

                VStack(spacing: 12) {
                    PrimaryButton("Continue") { onNext() }
                    SecondaryButton(title: "Back") { onBack() }
                }
                .padding(.bottom, 40)
            }
        }
    }

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(.caption).foregroundColor(Color(white: 0.4)).padding(.horizontal, 24)
    }

    @ViewBuilder
    private func yearPicker(_ label: String, selection: Binding<Int>, years: [Int]) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundColor(Color(white: 0.6))
            Spacer()
            Picker("", selection: selection) {
                ForEach(years, id: \.self) { Text(String($0)).tag($0) }
            }
            .pickerStyle(.menu)
            .tint(.white)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Step 4: Practice & Location

struct OnboardingStep4Practice: View {
    @ObservedObject var vm: OnboardingViewModel
    let onNext: () -> Void
    let onBack: () -> Void
    @State private var stateSearch = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                OnboardingHeader(
                    step: 4,
                    title: "Practice & Location",
                    subtitle: "Where do you work and what type of practice?"
                )

                VStack(alignment: .leading, spacing: 20) {
                    // Institution
                    Text("Current Institution").font(.caption).foregroundColor(Color(white: 0.4)).padding(.horizontal, 24)
                    TextField("Hospital or practice name", text: $vm.currentInstitution).modifier(TextFieldModifier())

                    // Practice Type
                    Text("Practice Type").font(.caption).foregroundColor(Color(white: 0.4)).padding(.horizontal, 24)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(PracticeType.allCases, id: \.self) { pt in
                                ChipToggle(label: pt.rawValue, selected: vm.practiceType == pt) {
                                    vm.practiceType = pt
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    // State Licenses
                    Text("State Licenses").font(.caption).foregroundColor(Color(white: 0.4)).padding(.horizontal, 24)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(usStates, id: \.self) { state in
                                ChipToggle(label: state, selected: vm.stateLicenses.contains(state)) {
                                    if vm.stateLicenses.contains(state) {
                                        vm.stateLicenses.removeAll { $0 == state }
                                    } else {
                                        vm.stateLicenses.append(state)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }

                    // Selected state tags
                    if !vm.stateLicenses.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(vm.stateLicenses, id: \.self) { state in
                                    Text(state)
                                        .font(.caption).fontWeight(.medium)
                                        .padding(.horizontal, 10).padding(.vertical, 5)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }

                    // Location
                    Text("Metro Area / Region").font(.caption).foregroundColor(Color(white: 0.4)).padding(.horizontal, 24)
                    TextField("e.g. New York, NY", text: $vm.locationRegion).modifier(TextFieldModifier())

                    // Languages
                    Text("Languages Spoken").font(.caption).foregroundColor(Color(white: 0.4)).padding(.horizontal, 24)
                    FlowChips(items: spokenLanguages, selected: $vm.languagesSpoken)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }

                Spacer().frame(height: 32)

                VStack(spacing: 12) {
                    PrimaryButton("Continue") { onNext() }
                    SecondaryButton(title: "Back") { onBack() }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// Flow layout for language chips
private struct FlowChips: View {
    let items: [String]
    @Binding var selected: [String]

    var body: some View {
        var chips: [String] = []
        return GeometryReader { geo in
            self.generateContent(in: geo)
        }
        .frame(height: 80)
    }

    private func generateContent(in geo: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                ChipToggle(label: item, selected: selected.contains(item)) {
                    if selected.contains(item) { selected.removeAll { $0 == item } }
                    else { selected.append(item) }
                }
                .alignmentGuide(.leading) { d in
                    if abs(width - d.width) > geo.size.width {
                        width = 0; height -= d.height + 8
                    }
                    let result = width
                    if item == items.last { width = 0 } else { width -= d.width + 8 }
                    return result
                }
                .alignmentGuide(.top) { _ in
                    let result = height
                    if item == items.last { height = 0 }
                    return result
                }
            }
        }
    }
}

// MARK: - Step 5: Networking Preferences

struct OnboardingStep5Networking: View {
    @ObservedObject var vm: OnboardingViewModel
    let onBack: () -> Void
    @State private var error: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                OnboardingHeader(
                    step: 5,
                    title: "Networking Preferences",
                    subtitle: "Let colleagues know how they can connect with you."
                )

                VStack(spacing: 0) {
                    preferenceToggle(
                        icon: "arrow.left.arrow.right.circle",
                        title: "Accepting Referrals",
                        subtitle: "Colleagues can refer patients to you",
                        isOn: $vm.isAcceptingReferrals
                    )
                    Divider().background(Color(white: 0.12))

                    preferenceToggle(
                        icon: "flask",
                        title: "Open to Collaboration",
                        subtitle: "Research or clinical collaboration",
                        isOn: $vm.isOpenToCollaboration
                    )
                    Divider().background(Color(white: 0.12))

                    preferenceToggle(
                        icon: "graduationcap",
                        title: "Available as Mentor",
                        subtitle: "Residents and students can reach out",
                        isOn: $vm.isMentor
                    )
                }
                .background(Color(white: 0.08))
                .cornerRadius(14)
                .padding(.horizontal, 24)

                if let error {
                    Text(error).font(.caption).foregroundColor(.red).padding(.horizontal, 24).padding(.top, 12)
                }

                Spacer().frame(height: 40)

                VStack(spacing: 12) {
                    PrimaryButton("Complete Profile", loading: vm.isSaving) {
                        Task {
                            do { try await vm.save() }
                            catch { self.error = error.localizedDescription }
                        }
                    }
                    SecondaryButton(title: "Back") { onBack() }
                }
                .padding(.bottom, 48)
            }
        }
    }

    @ViewBuilder
    private func preferenceToggle(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title3).foregroundColor(Color(white: 0.5)).frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).fontWeight(.medium).foregroundColor(.white)
                Text(subtitle).font(.caption).foregroundColor(Color(white: 0.45))
            }
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(.blue)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}

// MARK: - Preview

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
