//
//  User.swift
//  MedTeam
//
//  Created by Robert Plummer on 6/25/24.
//

import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: String
    let email: String
    let fullname: String
    let username: String
    let credentials: String
    var profileImageUrl: String?
    var bio: String?
    var selectedSurgeryService: [String]?
    
}

