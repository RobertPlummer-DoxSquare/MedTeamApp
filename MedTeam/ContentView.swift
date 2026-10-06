//
//  ContentView.swift
//  MedTeam
//
//  Created by Robert Plummer on 6/24/24.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @StateObject var authService = AuthService.shared
    @ObservedObject var userService = UserService.shared

    var body: some View {
        ZStack {
            Color.nmaBackground.ignoresSafeArea()

            if authService.userSession != nil {
                if let user = userService.currentUser {
                    if user.termsAcceptedAt == nil {
                        TermsAgreementView()
                    } else if !user.onboardingCompleted {
                        OnboardingView()
                    } else {
                        MainTabView()
                    }
                } else {
                    ProgressView().tint(.nmaPrimary)
                }
            } else {
                LoginView()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
