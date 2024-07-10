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
    @State private var isShowingSettings = false // State to control navigation
    @State private var isGlowing = false // State to control the glow effect

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack {
                    // Background with profile details
                    ZStack(alignment: .topTrailing) {
                        Rectangle()
                            .foregroundColor(Color.black) // Fully black background
                            .cornerRadius(20)
                            .frame(height: 200)
                            .padding(.horizontal)
                        
                        Button(action: {
                            self.isShowingSettings = true // Show settings view
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2) // Decreased font size of the settings button
                                .foregroundColor(.white)
                                .padding(8) // Adjusted padding around the settings button
                        }
                        .padding(.top, 10)
                        .padding(.trailing, 16)

                        GeometryReader { geometry in
                            if let user = viewModel.currentUser {
                                let nameComponents = user.fullname.components(separatedBy: " ")
                                let firstInitial = String(nameComponents.first?.prefix(1) ?? "").capitalized
                                let lastInitial = String(nameComponents.last?.prefix(1) ?? "").capitalized
                                
                                // Profile initials or image in bottom left corner
                                Text(firstInitial + lastInitial)
                                    .font(.system(size: 24, weight: .semibold))
                                    .frame(width: 48, height: 48)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                                    .position(x: 72 / 2 + 32, y: geometry.size.height - 72 / 2 - 16) // Increased padding from left
                                
                                // Full name and username centered
                                VStack {
                                    Text(user.fullname)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Text(user.username)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                                
                                // MD credentials in bottom right corner with green color and glow effect
                                Text(user.credentials)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                                    .shadow(color: isGlowing ? .green : .clear, radius: 16, x: 0, y: 0) // Conditional shadow for glow effect
                                    .position(x: geometry.size.width - 72, y: geometry.size.height - 36) // Increased padding from right
                                    .onAppear {
                                        withAnimation(Animation.easeInOut(duration: 1.0).repeatForever()) {
                                            self.isGlowing.toggle()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 16)
                    
                    // Additional information text input (commented out for now)
                    // TextField("Additional Information", text: $additionalInformation)
                    //    .textFieldStyle(RoundedBorderTextFieldStyle())
                    //    .padding()
                    //    .background(Color.white)
                    //    .cornerRadius(8)
                    //    .padding(.horizontal)
                    //    .offset(y: 180)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingSettings) {
                Settings() // Present Settings view as a sheet
            }
        }
    }
}

struct CurrentUserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        CurrentUserProfileView()
    }
}
