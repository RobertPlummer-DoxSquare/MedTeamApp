//
//  ContentViewModel.swift
//  MedTeam
//
//  Created by Robert Plummer on 6/25/24.
//

import SwiftUI
import Combine
import FirebaseAuth

class ContentViewModel: ObservableObject {
    @Published var isUserLoggedIn = false
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkUserSession()
        setupSubscribers()
    }
    
    private func setupSubscribers() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isUserLoggedIn = user != nil
        }
    }
    
    func checkUserSession() {
        self.isUserLoggedIn = Auth.auth().currentUser != nil
    }
}

