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
    @State private var showHamburger = false
    @State private var showSettingsView = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemBlue)
                    .frame(height: geometry.size.height * 0.4)
                    .edgesIgnoringSafeArea(.top)

                if authService.userSession != nil {
                    MainTabView()
                        .environmentObject(authService)

                    if showHamburger {
                        Hamburger(showHamburger: $showHamburger, showSettingsView: $showSettingsView)
                            .environmentObject(authService)
                    }
                } else {
                    LoginView()
                        .environmentObject(authService)
                }
            }
        }
        .sheet(isPresented: $showSettingsView) {
            Settings()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

