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
    @State private var email = ""
    @State private var password = ""
    @State private var fullname = ""
    @State private var username = ""
    @State private var credentials = ""
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            
            Image("MedIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
                .padding()
            
            TextField("Enter your email", text: $viewModel.email)
                .autocapitalization(.none)
                .modifier(TextFieldModifier())
            
            
            SecureField("Enter your password", text: $viewModel.password)
                .modifier(TextFieldModifier())
            
            TextField("Enter your full name", text: $viewModel.fullname)
                .modifier(TextFieldModifier())

            TextField("Enter your username", text: $viewModel.username)
                .autocapitalization(.none)
                .modifier(TextFieldModifier())

            TextField("Enter your Credentials MD, DO, MPH, FACS, etc.", text: $credentials)
                .modifier(TextFieldModifier())
           
            Button {
                Task {
                    do {
                        viewModel.credentials = credentials // Ensure credentials are set in ViewModel
                        try await viewModel.createUser()
                        print("User creation succeeded")
                    } catch {
                        print("User creation failed: \(error.localizedDescription)")
                    }
                }
            } label: {
                Text("Sign Up")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 325, height: 44)
                    .background(.blue)
                    .cornerRadius(8)
            }
            .padding(.vertical)
            
            Spacer()
            Divider()
                
            Button {
                dismiss()
            } label: {
                HStack(spacing: 3) {
                    Text("Already have an account?")
                    NavigationLink(
                        destination: /*@START_MENU_TOKEN@*/Text("Destination")/*@END_MENU_TOKEN@*/,
                        label: {
                            /*@START_MENU_TOKEN@*/Text("Navigate")/*@END_MENU_TOKEN@*/
                        })
                    Text("Sign In")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .font(.footnote)
            }
            .padding(.vertical, 16)
        }
        .background(customBackgroundColor.ignoresSafeArea()) // Apply custom background color
        .onAppear {
            print("RegistrationView appeared")
        }
    }
}

struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView()
    }
}

