//
//  SessionViewModel.swift
//  MedTeam
//
//  Created by Robert Plummer on 6/27/24.
//

import Firebase
import FirebaseFirestoreSwift

struct Session: Identifiable, Codable {
    let id: String
    let userID: String
    let hospitalLocation: String
    let position: String
    let selectedDays: [Int]
    let selectedServices: [String] // New property to store selected surgery services
    
    // Additional initializer if needed
    init(id: String, userID: String, hospitalLocation: String, position: String, selectedDays: [Int], selectedServices: [String]) {
        self.id = id
        self.userID = userID
        self.hospitalLocation = hospitalLocation
        self.position = position
        self.selectedDays = selectedDays
        self.selectedServices = selectedServices
    }
}
