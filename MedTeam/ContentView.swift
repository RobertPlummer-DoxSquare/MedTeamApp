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
                        Hamburger(showHamburger: $showHamburger)
                            .environmentObject(authService)
                    }
                } else {
                    LoginView()
                        .environmentObject(authService)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
