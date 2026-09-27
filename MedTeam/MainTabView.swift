//
//  MainTabView.swift
//  MedTeam
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
        appearance.backgroundColor = UIColor(Color.nmaSurface)

        let item = UITabBarItemAppearance()
        item.normal.iconColor   = UIColor(Color.nmaSecondary)
        item.selected.iconColor = UIColor(Color.nmaPrimary)
        item.normal.titleTextAttributes   = [.foregroundColor: UIColor(Color.nmaSecondary)]
        item.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.nmaPrimary)]

        appearance.stackedLayoutAppearance      = item
        appearance.inlineLayoutAppearance       = item
        appearance.compactInlineLayoutAppearance = item

        UITabBar.appearance().standardAppearance   = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Color.nmaBackground)
        navAppearance.shadowColor = UIColor(Color.nmaBorder)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor(Color.nmaPrimary)]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.nmaPrimary)]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(Color.nmaPrimary)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            MemberDirectoryView()
                .tabItem { Label("Directory", systemImage: selectedTab == 0 ? "person.2.fill" : "person.2") }
                .tag(0)

            PingInboxView()
                .tabItem { Label("Notifications", systemImage: selectedTab == 1 ? "bell.fill" : "bell") }
                .badge(pingInboxVM.unreadCount)
                .tag(1)

            ConversationListView(viewModel: conversationVM)
                .tabItem { Label("Messages", systemImage: selectedTab == 2 ? "message.fill" : "message") }
                .tag(2)

            CurrentUserProfileView()
                .tabItem { Label("Profile", systemImage: selectedTab == 3 ? "person.fill" : "person") }
                .tag(3)
        }
        .tint(Color.nmaPrimary)
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
