//
//  MainTabView.swift
//  MedTeam
//
//  Created by Robert Plummer on 6/24/24.
//

import SwiftUI

let backgroundF = Color.clear

struct MainTabView: View {
    init() {
        // Hide the tab bar border/frame using UIKit
        let appearance = UITabBarAppearance()
        appearance.backgroundImage = UIImage()
        appearance.shadowImage = UIImage()
        UITabBar.appearance().standardAppearance = appearance
        
        UINavigationBar.appearance().barTintColor = .clear
    }
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)
            
            ExploreView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                }
                .tag(1)
            
            CurrentUserProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "person.fill" : "person")
                }
                .tag(2)
        }
        .onAppear {
            // Set UITabBar's background color to clear when ThreadsTabView appears
            let appearance = UITabBarAppearance()
            appearance.backgroundColor = .clear
            UITabBar.appearance().standardAppearance = appearance
        }
        .tint(.black)
    }
}


// Other views...

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
