//
//  ExploreView.swift
//  MedTeam
//
//  Created by Robert Plummer on 6/24/24.
//
import SwiftUI

struct ExploreView: View {
    @State private var searchText = ""
    @StateObject var viewModel = ExploreViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredUsers) { user in
                            UserProfileView(user: user)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .navigationTitle("Search")
                .searchable(text: $searchText, prompt: "Search")
            }
        }
        .foregroundColor(.black) // Set text color to black for the entire view
    }
    
    // Computed property to filter users based on the search text
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return viewModel.users
        } else {
            return viewModel.users.filter { $0.fullname.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

struct UserProfileView: View {
    let user: User
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .foregroundColor(Color.black.opacity(1))
                .cornerRadius(20)
                .frame(height: 150)
                .frame(maxWidth: .infinity)
            
            VStack(alignment: .center, spacing: 8) {
                // Centered fullname and username
                Spacer()
                
                Text(user.fullname)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(user.username)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            
            HStack {
                VStack(alignment: .leading) {
                    // Align profile image and credentials at the bottom
                    Spacer()
                    
                    HStack {
                        // Profile image
                        if let imageUrl = user.profileImageUrl, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 30, height: 30)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 30, height: 30)
                                        .clipShape(Circle())
                                case .failure:
                                    Image(systemName: "person.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(.white)
                                @unknown default:
                                    Image(systemName: "person.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(.white)
                                }
                            }
                        } else {
                            Image(systemName: "person.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 30, height: 30)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        // Credentials
                        Text(user.credentials)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.blue.opacity(0.8))
                            .padding([.bottom, .trailing], 16) // Add padding to move it to the bottom right corner
                    }
                }
            }
            .padding([.leading, .trailing], 16) // Adjust the padding to make room for the profile picture and credentials
        }
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
    }
}
