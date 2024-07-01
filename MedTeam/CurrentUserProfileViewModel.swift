//
//  Profile.swift
//  MedTeam
//
//  Created by Robert Plummer on 6/24/24.
//

import Foundation
import Combine
import PhotosUI
import SwiftUI

class CurrentUserProfileViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var selectedItem: PhotosPickerItem? {
        didSet { Task { await loadImage() } }
    }
    @Published var profileImage: Image?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSubscribers()
    }
    
    private func setupSubscribers() {
        // Subscribe to changes in currentUser from UserService
        UserService.shared.$currentUser
            .sink { [weak self] user in
                self?.currentUser = user
            }
            .store(in: &cancellables)
    }
    
    private func loadImage() async {
        guard let item = selectedItem else { return }
        do {
            // Load data from selected PhotosPickerItem
            let data = try await item.loadTransferable(type: Data.self)
            
            // Convert data to UIImage
            guard let uiImage = UIImage(data: data!) else { return }
            
            // Convert UIImage to SwiftUI Image
            self.profileImage = Image(uiImage: uiImage)
        } catch {
            print("Failed to load image: \(error.localizedDescription)")
        }
    }
}


