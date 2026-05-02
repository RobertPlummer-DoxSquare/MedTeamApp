//
//  NPIService.swift
//  MedTeam
//

import Foundation

struct NPIResult {
    let npiNumber: String
    let firstName: String
    let lastName: String
    let credential: String
    let specialty: String
    let organizationName: String?
    let state: String?

    var fullName: String {
        "\(firstName.capitalized) \(lastName.capitalized)"
    }
}

enum NPILookupError: LocalizedError {
    case invalidNPI, notFound, networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidNPI:        return "Please enter a valid 10-digit NPI number."
        case .notFound:          return "No provider found with this NPI number."
        case .networkError(let e): return e.localizedDescription
        }
    }
}

class NPIService {
    static func lookup(npi: String) async throws -> NPIResult {
        guard npi.count == 10, npi.allSatisfy(\.isNumber) else {
            throw NPILookupError.invalidNPI
        }

        let urlString = "https://npiregistry.cms.hhs.gov/api/?number=\(npi)&version=2.1"
        guard let url = URL(string: urlString) else { throw NPILookupError.invalidNPI }

        let (data, _): (Data, URLResponse)
        do {
            (data, _) = try await URLSession.shared.data(from: url)
        } catch {
            throw NPILookupError.networkError(error)
        }

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let results = json["results"] as? [[String: Any]],
            let first = results.first
        else {
            throw NPILookupError.notFound
        }

        let basic = first["basic"] as? [String: Any] ?? [:]
        let taxonomies = first["taxonomies"] as? [[String: Any]] ?? []
        let addresses = first["addresses"] as? [[String: Any]] ?? []
        let primary = addresses.first(where: { ($0["address_purpose"] as? String) == "LOCATION" })
            ?? addresses.first
            ?? [:]

        return NPIResult(
            npiNumber: npi,
            firstName: basic["first_name"] as? String ?? "",
            lastName: basic["last_name"] as? String ?? "",
            credential: basic["credential"] as? String ?? "",
            specialty: taxonomies.first?["desc"] as? String ?? "",
            organizationName: primary["organization_name"] as? String,
            state: primary["state"] as? String
        )
    }
}
