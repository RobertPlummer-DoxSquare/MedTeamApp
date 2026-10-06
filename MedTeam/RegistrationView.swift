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
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.nmaBackground.ignoresSafeArea()

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
                        .foregroundColor(.nmaPrimary)
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
                    }

                    TermsCheckbox(isOn: $viewModel.agreedToTerms)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                    }

                    Spacer().frame(height: 32)

                    Button {
                        Task { await viewModel.createUser() }
                    } label: {
                        Group {
                            if viewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Sign Up")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.nmaPrimary)
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.bottom, 40)

                    Spacer()

                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .foregroundColor(.nmaSecondary)
                            Text("Sign In")
                                .fontWeight(.semibold)
                                .foregroundColor(.nmaPrimary)
                        }
                        .font(.footnote)
                    }
                    .padding(.bottom, 32)
                }
            }
        }
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView()
    }
}
