//
//  User.swift
//  MedTeam
//
//  Created by Robert Plummer on 6/25/24.
//

import Foundation

struct User: Identifiable, Codable, Hashable {
    // MARK: - Core
    let id: String
    var email: String
    var fullname: String
    var username: String
    var credentials: String
    var profileImageUrl: String?

    // MARK: - Legacy
    var bio: String?
    var selectedSurgeryService: [String]?

    // MARK: - Identity & Verification
    var npiNumber: String?
    var npiVerified: Bool

    // MARK: - Role & Specialty
    var degreeType: DegreeType?
    var specialty: String?
    var subspecialties: [String]
    var boardCertifications: [String]

    // MARK: - Training
    var medicalSchool: String?
    var medicalSchoolGradYear: Int?
    var residencyProgram: String?
    var residencyCompletionYear: Int?
    var fellowshipProgram: String?
    var fellowshipCompletionYear: Int?

    // MARK: - Practice
    var currentInstitution: String?
    var practiceType: PracticeType?
    var stateLicenses: [String]
    var isAcceptingReferrals: Bool
    var isOpenToCollaboration: Bool

    // MARK: - Networking
    var isMentor: Bool
    var languagesSpoken: [String]
    var locationRegion: String?

    // MARK: - Computed (not stored in Firestore)
    var profileCompletionPercent: Int {
        let checks: [Bool] = [
            npiNumber != nil,
            degreeType != nil,
            specialty != nil,
            !subspecialties.isEmpty,
            medicalSchool != nil,
            residencyProgram != nil,
            currentInstitution != nil,
            practiceType != nil,
            !stateLicenses.isEmpty,
            !languagesSpoken.isEmpty
        ]
        return checks.filter { $0 }.count * 10
    }

    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case id, email, fullname, username, credentials, profileImageUrl
        case bio, selectedSurgeryService
        case npiNumber, npiVerified
        case degreeType, specialty, subspecialties, boardCertifications
        case medicalSchool, medicalSchoolGradYear
        case residencyProgram, residencyCompletionYear
        case fellowshipProgram, fellowshipCompletionYear
        case currentInstitution, practiceType, stateLicenses
        case isAcceptingReferrals, isOpenToCollaboration
        case isMentor, languagesSpoken, locationRegion
    }

    // MARK: - Custom Decoding (graceful defaults for missing fields)
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                     = try c.decode(String.self, forKey: .id)
        email                  = try c.decode(String.self, forKey: .email)
        fullname               = try c.decode(String.self, forKey: .fullname)
        username               = try c.decode(String.self, forKey: .username)
        credentials            = try c.decode(String.self, forKey: .credentials)
        profileImageUrl        = try c.decodeIfPresent(String.self, forKey: .profileImageUrl)
        bio                    = try c.decodeIfPresent(String.self, forKey: .bio)
        selectedSurgeryService = try c.decodeIfPresent([String].self, forKey: .selectedSurgeryService)
        npiNumber              = try c.decodeIfPresent(String.self, forKey: .npiNumber)
        npiVerified            = try c.decodeIfPresent(Bool.self, forKey: .npiVerified) ?? false
        degreeType             = try c.decodeIfPresent(DegreeType.self, forKey: .degreeType)
        specialty              = try c.decodeIfPresent(String.self, forKey: .specialty)
        subspecialties         = try c.decodeIfPresent([String].self, forKey: .subspecialties) ?? []
        boardCertifications    = try c.decodeIfPresent([String].self, forKey: .boardCertifications) ?? []
        medicalSchool          = try c.decodeIfPresent(String.self, forKey: .medicalSchool)
        medicalSchoolGradYear  = try c.decodeIfPresent(Int.self, forKey: .medicalSchoolGradYear)
        residencyProgram       = try c.decodeIfPresent(String.self, forKey: .residencyProgram)
        residencyCompletionYear = try c.decodeIfPresent(Int.self, forKey: .residencyCompletionYear)
        fellowshipProgram      = try c.decodeIfPresent(String.self, forKey: .fellowshipProgram)
        fellowshipCompletionYear = try c.decodeIfPresent(Int.self, forKey: .fellowshipCompletionYear)
        currentInstitution     = try c.decodeIfPresent(String.self, forKey: .currentInstitution)
        practiceType           = try c.decodeIfPresent(PracticeType.self, forKey: .practiceType)
        stateLicenses          = try c.decodeIfPresent([String].self, forKey: .stateLicenses) ?? []
        isAcceptingReferrals   = try c.decodeIfPresent(Bool.self, forKey: .isAcceptingReferrals) ?? false
        isOpenToCollaboration  = try c.decodeIfPresent(Bool.self, forKey: .isOpenToCollaboration) ?? false
        isMentor               = try c.decodeIfPresent(Bool.self, forKey: .isMentor) ?? false
        languagesSpoken        = try c.decodeIfPresent([String].self, forKey: .languagesSpoken) ?? []
        locationRegion         = try c.decodeIfPresent(String.self, forKey: .locationRegion)
    }

    // MARK: - Base init (used by AuthService on account creation)
    init(id: String, email: String, fullname: String, username: String, credentials: String) {
        self.id = id
        self.email = email
        self.fullname = fullname
        self.username = username
        self.credentials = credentials
        self.npiVerified = false
        self.subspecialties = []
        self.boardCertifications = []
        self.stateLicenses = []
        self.isAcceptingReferrals = false
        self.isOpenToCollaboration = false
        self.isMentor = false
        self.languagesSpoken = []
    }
}

// MARK: - Enums

enum DegreeType: String, Codable, CaseIterable {
    case md = "MD"
    case doOsteopathic = "DO"
    case np = "NP"
    case pa = "PA"
    case rn = "RN"
    case pharmd = "PharmD"
    case phd = "PhD"
    case other = "Other"
}

enum PracticeType: String, Codable, CaseIterable {
    case academic = "Academic Medical Center"
    case privateGroup = "Private Group Practice"
    case communityHospital = "Community Hospital"
    case locums = "Locum Tenens"
    case telehealth = "Telehealth"
    case research = "Research / Industry"
    case retired = "Retired"
    case resident = "Resident / Fellow in Training"
}
