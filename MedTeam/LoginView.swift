    //
//  LoginView.swift
//  MedTeam
//
//  Created by Robert Plummer on 6/24/24.
//

import Foundation
import SwiftUI

let backgroundColor = Color.black

struct LoginView: View {
    @StateObject var viewModel = LoginViewModel()
    @State private var email = ""
    @State private var password = ""
    
    @State private var showFeedView = false
    @State private var showAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                .ignoresSafeArea()

                VStack {
                    Spacer()
                    
                    Image("MedIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .padding()
                    
//                    Spacer()

                    TextField("Enter your email", text: $viewModel.email)
                        .autocapitalization(.none)
                        .modifier(TextFieldModifier())
                        .background(Color.black)
                        .foregroundColor(.gray)

                    SecureField("Enter your password", text: $viewModel.password)
                        .modifier(TextFieldModifier())
                        .background(Color.black)
                        .foregroundColor(.gray)
                    
                    NavigationLink {
                        Text("Forgot password")
                    } label: {
                        Text("Forgot password")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .padding(.vertical)
                            .padding(.trailing, 28)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

//                    Spacer()
//
                    Button {
                        Task {
                            await viewModel.login()
                            if viewModel.isAuthenticated {
                                print("Login successful, routing to FeedView")
                                ContentView()
                            } else {
                                print("Login failed, showing alert")
                                showAlert = true
                            }
                        }
                    } label: {
                        Text("Log In")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 325, height: 44)
                            .background(.blue)
                            .cornerRadius(8)
                    }
//
                    Divider()
//
                    Spacer()
                    
                    NavigationLink {
                        RegistrationView()
                            .navigationBarBackButtonHidden(true)
                    } label: {
                        HStack(spacing: 3) {
                            Text("Don't have an account? ")
                            
                            Text("Sign Up")
                                .fontWeight(.semibold)
                            
                        }
                        .foregroundColor(.white)
                        .font(.footnote)
                    }
                    .padding(.vertical, 16)
                    
//
//                    Button(action: {
//                        do {
//                            try Auth.auth().signOut()
//                            print("User logged out successfully")
//                        } catch {
//                            print("Error signing out: \(error.localizedDescription)")
//                        }
//                    }) {
//                        Text("Logout")
//                            .font(.subheadline)
//                            .fontWeight(.semibold)
//                            .foregroundColor(.white)
//                            .frame(width: 352, height: 44)
//                            .background(.red)
//                            .cornerRadius(8)
//                    }
//
//                }
//                .padding()
//                .alert(isPresented: $showAlert) {
//                    Alert(
//                        title: Text("Login Error"),
//                        message: Text(viewModel.loginError ?? "Unknown error"),
//                        dismissButton: .default(Text("OK"))
//                    )
//                }
//
//                NavigationLink(
////                    destination: FeedView()
//                        .navigationBarBackButtonHidden(true),
//                    isActive: $showFeedView
//                ) {
//                    EmptyView()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

extension Color {
    static func createFromRGBA(_ red: String, _ green: String, _ blue: String, _ alpha: String) -> Color {
        guard let redValue = Double(red),
              let greenValue = Double(green),
              let blueValue = Double(blue),
              let alphaValue = Double(alpha) else {
            return Color.clear
        }

        return Color(red: redValue, green: greenValue, blue: blueValue, opacity: alphaValue)
    }
}
