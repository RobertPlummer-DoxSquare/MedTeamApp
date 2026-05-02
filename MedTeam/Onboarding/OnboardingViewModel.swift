//
//  OnboardingViewModel.swift
//  MedTeam
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

enum LookupState: Equatable {
    case idle, loading, success, failure(String)
}

class OnboardingViewModel: ObservableObject {
    // MARK: - Step 1: NPI
    @Published var npiNumber = ""
    @Published var lookupState: LookupState = .idle
    @Published var npiResult: NPIResult?

    // MARK: - Step 2: Credentials
    @Published var degreeType: DegreeType = .md
    @Published var specialty = ""
    @Published var subspecialties: [String] = []
    @Published var boardCertifications: [String] = []
    @Published var newCertification = ""

    // MARK: - Step 3: Training
    @Published var medicalSchool = ""
    @Published var medicalSchoolGradYear = OnboardingViewModel.thisYear
    @Published var residencyProgram = ""
    @Published var residencyCompletionYear = OnboardingViewModel.thisYear
    @Published var hasFellowship = false
    @Published var fellowshipProgram = ""
    @Published var fellowshipCompletionYear = OnboardingViewModel.thisYear

    // MARK: - Step 4: Practice
    @Published var currentInstitution = ""
    @Published var practiceType: PracticeType = .academic
    @Published var stateLicenses: [String] = []
    @Published var locationRegion = ""
    @Published var languagesSpoken: [String] = ["English"]

    // MARK: - Step 5: Networking
    @Published var isAcceptingReferrals = false
    @Published var isOpenToCollaboration = false
    @Published var isMentor = false

    @Published var isSaving = false

    static var thisYear: Int { Calendar.current.component(.year, from: Date()) }

    // MARK: - NPI Lookup
    func lookupNPI() async {
        await MainActor.run { lookupState = .loading }
        do {
            let result = try await NPIService.lookup(npi: npiNumber)
            await MainActor.run {
                npiResult = result
                lookupState = .success
                if !result.specialty.isEmpty, specialty.isEmpty {
                    specialty = result.specialty
                }
                if let org = result.organizationName, currentInstitution.isEmpty {
                    currentInstitution = org
                }
                if let state = result.state, !stateLicenses.contains(state) {
                    stateLicenses.append(state)
                }
            }
        } catch {
            await MainActor.run {
                lookupState = .failure(error.localizedDescription)
            }
        }
    }

    // MARK: - Save to Firestore
    @MainActor
    func save() async throws {
        isSaving = true
        defer { isSaving = false }

        guard let uid = Auth.auth().currentUser?.uid else { return }

        var data: [String: Any] = [
            "npiNumber":              npiNumber,
            "npiVerified":            npiResult != nil,
            "degreeType":             degreeType.rawValue,
            "specialty":              specialty,
            "subspecialties":         subspecialties,
            "boardCertifications":    boardCertifications,
            "medicalSchool":          medicalSchool,
            "medicalSchoolGradYear":  medicalSchoolGradYear,
            "residencyProgram":       residencyProgram,
            "residencyCompletionYear": residencyCompletionYear,
            "currentInstitution":     currentInstitution,
            "practiceType":           practiceType.rawValue,
            "stateLicenses":          stateLicenses,
            "locationRegion":         locationRegion,
            "languagesSpoken":        languagesSpoken,
            "isAcceptingReferrals":   isAcceptingReferrals,
            "isOpenToCollaboration":  isOpenToCollaboration,
            "isMentor":               isMentor
        ]

        if hasFellowship {
            data["fellowshipProgram"] = fellowshipProgram
            data["fellowshipCompletionYear"] = fellowshipCompletionYear
        }

        try await Firestore.firestore().collection("users").document(uid).updateData(data)
        try await UserService.shared.fetchCurrentUser()
    }
}
