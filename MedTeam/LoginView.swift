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
    @ObservedObject private var authService = AuthService.shared
    @State private var showResetPrompt = false
    @State private var showResetResult = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.nmaBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    Image("MedIcon")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(Circle())
                        .padding(.bottom, 16)

                    Text("MedTeam")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.nmaPrimary)
                        .padding(.bottom, 48)

                    TextField("Email", text: $viewModel.email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .modifier(TextFieldModifier())
                        .padding(.bottom, 12)

                    SecureField("Password", text: $viewModel.password)
                        .modifier(TextFieldModifier())

                    if let error = viewModel.loginError {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                    }

                    Button {
                        viewModel.resetEmail = viewModel.email
                        showResetPrompt = true
                    } label: {
                        Text("Forgot password?")
                            .font(.footnote)
                            .foregroundColor(.nmaSecondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                    }

                    Spacer().frame(height: 32)

                    Button {
                        Task { await viewModel.login() }
                    } label: {
                        Group {
                            if viewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Log In")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.nmaPrimary.opacity(viewModel.canSubmit || viewModel.isLoading ? 1 : 0.4))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                    }
                    .disabled(!viewModel.canSubmit)

                    Spacer()

                    NavigationLink {
                        RegistrationView()
                            .navigationBarBackButtonHidden(true)
                    } label: {
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundColor(.nmaSecondary)
                            Text("Sign Up")
                                .fontWeight(.semibold)
                                .foregroundColor(.nmaPrimary)
                        }
                        .font(.footnote)
                    }
                    .padding(.bottom, 32)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert("Reset Password", isPresented: $showResetPrompt) {
                TextField("Email", text: $viewModel.resetEmail)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                Button("Send Link") {
                    Task {
                        await viewModel.sendPasswordReset()
                        showResetResult = true
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter your account email and we'll send you a link to reset your password.")
            }
            .alert("Reset Password", isPresented: $showResetResult) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.resetResultMessage ?? "")
            }
            .alert("Account Deleted", isPresented: $authService.didDeleteAccount) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your account and profile have been permanently deleted.")
            }
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
