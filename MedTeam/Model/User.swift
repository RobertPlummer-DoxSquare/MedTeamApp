//
//  User.swift
//  MedTeam
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
    var npiStatus: NPIStatus

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
    var isOpenToReferrals: Bool
    var isOpenToCollaboration: Bool
    var officePhone: String?

    // MARK: - NMA Region
    var nmaRegion: NMARegion?
    var nmaRegionRole: NMARegionRole?

    // MARK: - Networking
    var isMentor: Bool
    var languagesSpoken: [String]
    var locationRegion: String?

    // MARK: - Computed (not stored in Firestore)
    var profileCompletionPercent: Int {
        let checks: [Bool] = [
            !(npiNumber ?? "").isEmpty,
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

    var isChairperson: Bool {
        nmaRegionRole == .chairperson
    }

    /// "Dr. Smith" for physicians (MD/DO), otherwise the full name.
    var formalName: String {
        let physicianDegrees: Set<String> = ["MD", "DO"]
        let credentialTokens = credentials.uppercased()
            .components(separatedBy: CharacterSet.letters.inverted)
        let isPhysician = degreeType == .md || degreeType == .doOsteopathic
            || credentialTokens.contains { physicianDegrees.contains($0) }
        let suffixes: Set<String> = ["jr", "jr.", "sr", "sr.", "ii", "iii", "iv"]
        let lastName = fullname.split(separator: " ").map(String.init)
            .last { !suffixes.contains($0.lowercased()) } ?? fullname
        return isPhysician ? "Dr. \(lastName)" : fullname
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
        case isOpenToReferrals = "isAcceptingReferrals"
        case isOpenToCollaboration
        case officePhone
        case nmaRegion, nmaRegionRole
        case isMentor, languagesSpoken, locationRegion
        case npiStatus
    }

    // MARK: - Custom Decoding
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                      = try c.decode(String.self, forKey: .id)
        email                   = try c.decode(String.self, forKey: .email)
        fullname                = try c.decode(String.self, forKey: .fullname)
        username                = try c.decode(String.self, forKey: .username)
        credentials             = try c.decode(String.self, forKey: .credentials)
        profileImageUrl         = try c.decodeIfPresent(String.self, forKey: .profileImageUrl)
        bio                     = try c.decodeIfPresent(String.self, forKey: .bio)
        selectedSurgeryService  = try c.decodeIfPresent([String].self, forKey: .selectedSurgeryService)
        npiNumber               = try c.decodeIfPresent(String.self, forKey: .npiNumber)
        npiVerified             = try c.decodeIfPresent(Bool.self, forKey: .npiVerified) ?? false
        // Older documents have no npiStatus; derive it from npiVerified.
        npiStatus               = try c.decodeIfPresent(NPIStatus.self, forKey: .npiStatus)
                                  ?? (npiVerified ? .verified : .none)
        degreeType              = try c.decodeIfPresent(DegreeType.self, forKey: .degreeType)
        specialty               = try c.decodeIfPresent(String.self, forKey: .specialty)
        subspecialties          = try c.decodeIfPresent([String].self, forKey: .subspecialties) ?? []
        boardCertifications     = try c.decodeIfPresent([String].self, forKey: .boardCertifications) ?? []
        medicalSchool           = try c.decodeIfPresent(String.self, forKey: .medicalSchool)
        medicalSchoolGradYear   = try c.decodeIfPresent(Int.self, forKey: .medicalSchoolGradYear)
        residencyProgram        = try c.decodeIfPresent(String.self, forKey: .residencyProgram)
        residencyCompletionYear = try c.decodeIfPresent(Int.self, forKey: .residencyCompletionYear)
        fellowshipProgram       = try c.decodeIfPresent(String.self, forKey: .fellowshipProgram)
        fellowshipCompletionYear = try c.decodeIfPresent(Int.self, forKey: .fellowshipCompletionYear)
        currentInstitution      = try c.decodeIfPresent(String.self, forKey: .currentInstitution)
        practiceType            = try c.decodeIfPresent(PracticeType.self, forKey: .practiceType)
        stateLicenses           = try c.decodeIfPresent([String].self, forKey: .stateLicenses) ?? []
        isOpenToReferrals       = try c.decodeIfPresent(Bool.self, forKey: .isOpenToReferrals) ?? false
        isOpenToCollaboration   = try c.decodeIfPresent(Bool.self, forKey: .isOpenToCollaboration) ?? false
        officePhone             = try c.decodeIfPresent(String.self, forKey: .officePhone)
        nmaRegion               = try c.decodeIfPresent(NMARegion.self, forKey: .nmaRegion)
        nmaRegionRole           = try c.decodeIfPresent(NMARegionRole.self, forKey: .nmaRegionRole)
        isMentor                = try c.decodeIfPresent(Bool.self, forKey: .isMentor) ?? false
        languagesSpoken         = try c.decodeIfPresent([String].self, forKey: .languagesSpoken) ?? []
        locationRegion          = try c.decodeIfPresent(String.self, forKey: .locationRegion)
    }

    // MARK: - Base init
    init(id: String, email: String, fullname: String, username: String, credentials: String) {
        self.id = id
        self.email = email
        self.fullname = fullname
        self.username = username
        self.credentials = credentials
        self.npiVerified = false
        self.npiStatus = .none
        self.subspecialties = []
        self.boardCertifications = []
        self.stateLicenses = []
        self.isOpenToReferrals = false
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

enum NPIStatus: String, Codable {
    case verified
    case pendingReview
    case none
}
