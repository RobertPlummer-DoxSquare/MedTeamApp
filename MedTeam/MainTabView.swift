//
//  MainTabView.swift
//  MedTeam
//
//  Created by Robert Plummer on 6/24/24.
//

import SwiftUI

let backgroundF = Color.clear

struct MainTabView: View {
    @StateObject private var pingInboxVM = PingInboxViewModel()
    @StateObject private var conversationVM = ConversationListViewModel()
    @State private var selectedTab = 0

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(white: 0.05, alpha: 1)

        let unselected = UITabBarItemAppearance()
        unselected.normal.iconColor = UIColor(white: 0.45, alpha: 1)
        unselected.selected.iconColor = .white

        appearance.stackedLayoutAppearance = unselected
        appearance.inlineLayoutAppearance = unselected
        appearance.compactInlineLayoutAppearance = unselected

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ExploreView()
                .tabItem { Label("Explore", systemImage: "magnifyingglass") }
                .tag(0)

            PingInboxView()
                .tabItem { Label("Pings", systemImage: selectedTab == 1 ? "bell.fill" : "bell") }
                .badge(pingInboxVM.unreadCount)
                .tag(1)

            ConversationListView(viewModel: conversationVM)
                .tabItem { Label("Messages", systemImage: selectedTab == 2 ? "message.fill" : "message") }
                .tag(2)

            CurrentUserProfileView()
                .tabItem { Label("Profile", systemImage: selectedTab == 3 ? "person.fill" : "person") }
                .tag(3)
        }
        .tint(.white)
        .onAppear {
            pingInboxVM.startListening()
            conversationVM.startListening()
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToMessages)) { _ in
            selectedTab = 2
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
