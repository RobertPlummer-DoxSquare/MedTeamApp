//
//  CurrentUserProfileView.swift
//  MedTeam
//
//  Created by Robert Plummer on 6/24/24.
//



import SwiftUI

struct CurrentUserProfileView: View {
    @StateObject var viewModel = CurrentUserProfileViewModel()
    @State private var showEditProfile = false
    @State private var additionalInformation = ""

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack {
                    // Background with profile details
                    ZStack(alignment: .top) {
                        Rectangle()
                            .foregroundColor(Color.black.opacity(1))
                            .cornerRadius(20)
                            .frame(height: 200)
                            .padding(.horizontal)
                        
                        VStack(alignment: .center, spacing: 8) {
                            if let user = viewModel.currentUser {
                                VStack(alignment: .center, spacing: 8) {
                                    // Profile initials or image
                                    let nameComponents = user.fullname.components(separatedBy: " ")
                                    let firstInitial = String(nameComponents.first?.prefix(1) ?? "").capitalized
                                    let lastInitial = String(nameComponents.last?.prefix(1) ?? "").capitalized
                                    
                                    Text(firstInitial + lastInitial)
                                        .font(.system(size: 36, weight: .bold))
                                        .frame(width: 72, height: 72)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                        .padding(.top, 16)
                                    
                                    Text(user.fullname)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Text(user.username)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    
                                    Text(user.credentials)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                            }
                        }
                    }
                    .padding(.top, 16)
                    
                    // Additional information text input
//                    TextField("Additional Information", text: $additionalInformation)
//                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                        .padding()
//                        .background(Color.white)
//                        .cornerRadius(8)
//                        .padding(.horizontal)
//                        .offset(y: 180)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CurrentUserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        CurrentUserProfileView()
    }
}

