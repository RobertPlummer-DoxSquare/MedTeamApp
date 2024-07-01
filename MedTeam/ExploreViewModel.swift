//
//  ExploreViewModel.swift
//  MedTeam
//
//  Created by Robert Plummer on 6/26/24.
//

import Foundation

class ExploreViewModel: ObservableObject {
    @Published var users = [User]()
    
    init() {
        Task { try await fetchUsers() }
    }
    @MainActor
    private func fetchUsers() async throws {
        self.users = try await UserService.fetchUsers()
        
        
    }
}
