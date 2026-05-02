//
//  RegistrationView.swift
//  MedTeam
//
//  Created by Robert Plummer on 6/24/24.
//
import SwiftUI

let customBackgroundColor = Color.black

struct RegistrationView: View {
    @StateObject var viewModel = RegistrationViewModel()
    @State private var credentials = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Image("MedIcon")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(Circle())
                        .padding(.top, 48)
                        .padding(.bottom, 16)

                    Text("Create Account")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.bottom, 40)

                    VStack(spacing: 12) {
                        TextField("Email", text: $viewModel.email)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .modifier(TextFieldModifier())

                        SecureField("Password", text: $viewModel.password)
                            .modifier(TextFieldModifier())

                        TextField("Full name", text: $viewModel.fullname)
                            .modifier(TextFieldModifier())

                        TextField("Username", text: $viewModel.username)
                            .autocapitalization(.none)
                            .modifier(TextFieldModifier())

                        TextField("Credentials (MD, DO, MPH, FACS…)", text: $credentials)
                            .modifier(TextFieldModifier())
                    }

                    Spacer().frame(height: 32)

                    Button {
                        Task {
                            do {
                                viewModel.credentials = credentials
                                try await viewModel.createUser()
                            } catch {
                                print("User creation failed: \(error.localizedDescription)")
                            }
                        }
                    } label: {
                        Text("Sign Up")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 40)

                    Spacer()

                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .foregroundColor(Color(white: 0.45))
                            Text("Sign In")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .font(.footnote)
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .colorScheme(.dark)
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView()
    }
}
