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

@MainActor
class OnboardingViewModel: ObservableObject {
    // MARK: - Screen 1: Member type
    @Published var memberType: MemberType = .clinician

    // MARK: - Screen 2: Verify (clinician NPI)
    @Published var npiNumber = ""
    @Published var lookupState: LookupState = .idle
    @Published var npiResult: NPIResult?
    @Published var npiNameMatches = false

    // MARK: - Screen 2: Verify (student school email)
    @Published var schoolEmail = ""
    @Published var schoolEmailState: LookupState = .idle
    @Published var schoolEmailSent = false

    // MARK: - Screen 3: Basics
    @Published var credentials = ""
    @Published var specialty = ""
    @Published var institution = ""
    @Published var nmaRegion: NMARegion?
    @Published var suggestedRegion: NMARegion?
    @Published var isMentor = false
    @Published var isOpenToCollaboration = false
    @Published var isOpenToReferrals = false
    @Published var officePhone = ""
    @Published var stateLicenses: [String] = []

    @Published var isSaving = false
    @Published var saveError: String?

    var npiStatus: NPIStatus {
        guard npiResult != nil else { return .none }
        return npiNameMatches ? .verified : .pendingReview
    }

    var canFinish: Bool {
        !specialty.isEmpty && !institution.trimmingCharacters(in: .whitespaces).isEmpty
            && (!isOpenToReferrals || !officePhone.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    // MARK: - NPI Lookup

    func lookupNPI() async {
        lookupState = .loading
        do {
            let result = try await NPIService.lookup(npi: npiNumber)
            let accountName = UserService.shared.currentUser?.fullname ?? ""
            npiResult = result
            npiNameMatches = NPIService.nameMatches(result, accountName: accountName)
            lookupState = .success
            if !result.credential.isEmpty, credentials.isEmpty { credentials = result.credential }
            if !result.specialty.isEmpty, specialty.isEmpty { specialty = result.specialty }
            if let org = result.organizationName, institution.isEmpty { institution = org }
            if let state = result.state {
                if !stateLicenses.contains(state) { stateLicenses.append(state) }
                if let region = NMARegion.fromState(state) {
                    suggestedRegion = region
                    if nmaRegion == nil { nmaRegion = region }
                }
            }
        } catch {
            npiResult = nil
            npiNameMatches = false
            lookupState = .failure(error.localizedDescription)
        }
    }

    // MARK: - School email

    func sendSchoolVerification() async {
        guard AuthService.isSchoolEmail(schoolEmail) else {
            schoolEmailState = .failure("Please use your school's .edu email address.")
            return
        }
        schoolEmailState = .loading
        do {
            try await AuthService.shared.sendSchoolVerification(to: schoolEmail)
            schoolEmailSent = true
            schoolEmailState = .idle
        } catch {
            schoolEmailState = .failure(AuthService.friendlyMessage(for: error))
        }
    }

    // MARK: - Save

    func save() async {
        isSaving = true
        defer { isSaving = false }
        saveError = nil

        var data: [String: Any] = [
            "memberType":            memberType.rawValue,
            "onboardingCompleted":   true,
            "credentials":           credentials.trimmingCharacters(in: .whitespaces),
            "specialty":             specialty,
            "currentInstitution":    institution.trimmingCharacters(in: .whitespaces),
            "isMentor":              isMentor,
            "isOpenToCollaboration": isOpenToCollaboration,
            "isAcceptingReferrals":  memberType == .clinician && isOpenToReferrals,
            "languagesSpoken":       ["English"]
        ]
        if let region = nmaRegion { data["nmaRegion"] = region.rawValue }
        if !officePhone.isEmpty { data["officePhone"] = officePhone }
        if !stateLicenses.isEmpty { data["stateLicenses"] = stateLicenses }

        if memberType == .clinician {
            // Only keep an NPI the registry recognized.
            data["npiNumber"]   = npiResult != nil ? npiNumber : ""
            data["npiVerified"] = npiStatus == .verified
            data["npiStatus"]   = npiStatus.rawValue
        }

        do {
            try await UserService.shared.updateFields(data)
        } catch {
            saveError = AuthService.friendlyMessage(for: error)
        }
    }
}
