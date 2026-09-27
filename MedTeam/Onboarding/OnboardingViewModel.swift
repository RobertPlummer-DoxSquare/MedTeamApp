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
    @Published var npiNameMatches = false

    var npiStatus: NPIStatus {
        guard npiResult != nil else { return .none }
        return npiNameMatches ? .verified : .pendingReview
    }

    // MARK: - Step 2: Credentials
    @Published var degreeType: DegreeType = .md
    @Published var specialty = ""
    @Published var subspecialties: [String] = []
    @Published var boardCertifications: [String] = []
    @Published var newCertification = ""

    // MARK: - Step 3: NMA Region
    @Published var nmaRegion: NMARegion?
    @Published var suggestedRegion: NMARegion?

    // MARK: - Step 4: Training
    @Published var medicalSchool = ""
    @Published var medicalSchoolGradYear = OnboardingViewModel.thisYear
    @Published var residencyProgram = ""
    @Published var residencyCompletionYear = OnboardingViewModel.thisYear
    @Published var hasFellowship = false
    @Published var fellowshipProgram = ""
    @Published var fellowshipCompletionYear = OnboardingViewModel.thisYear

    // MARK: - Step 5: Availability
    @Published var isOpenToReferrals = false
    @Published var isOpenToCollaboration = false
    @Published var isMentor = false

    // MARK: - Practice (populated from NPI, saved silently)
    @Published var currentInstitution = ""
    @Published var practiceType: PracticeType = .academic
    @Published var stateLicenses: [String] = []
    @Published var locationRegion = ""
    @Published var languagesSpoken: [String] = ["English"]

    @Published var isSaving = false

    static var thisYear: Int { Calendar.current.component(.year, from: Date()) }

    // MARK: - NPI Lookup
    func lookupNPI() async {
        await MainActor.run { lookupState = .loading }
        do {
            let result = try await NPIService.lookup(npi: npiNumber)
            let accountName = UserService.shared.currentUser?.fullname ?? ""
            await MainActor.run {
                npiResult = result
                npiNameMatches = NPIService.nameMatches(result, accountName: accountName)
                lookupState = .success
                if !result.specialty.isEmpty, specialty.isEmpty {
                    specialty = result.specialty
                }
                if let org = result.organizationName, currentInstitution.isEmpty {
                    currentInstitution = org
                }
                if let state = result.state {
                    if !stateLicenses.contains(state) { stateLicenses.append(state) }
                    if let region = NMARegion.fromState(state) {
                        suggestedRegion = region
                        if nmaRegion == nil { nmaRegion = region }
                    }
                }
            }
        } catch {
            await MainActor.run {
                npiResult = nil
                npiNameMatches = false
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
            // Only keep an NPI the registry recognized.
            "npiNumber":              npiResult != nil ? npiNumber : "",
            "npiVerified":            npiStatus == .verified,
            "npiStatus":              npiStatus.rawValue,
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
            "isAcceptingReferrals":   isOpenToReferrals,
            "isOpenToCollaboration":  isOpenToCollaboration,
            "isMentor":               isMentor
        ]

        if let region = nmaRegion {
            data["nmaRegion"] = region.rawValue
        }
        if hasFellowship {
            data["fellowshipProgram"] = fellowshipProgram
            data["fellowshipCompletionYear"] = fellowshipCompletionYear
        }

        try await Firestore.firestore().collection("users").document(uid).updateData(data)
        try await UserService.shared.fetchCurrentUser()
    }
}
