//
//  MainTabView.swift
//  MedTeam
//

import SwiftUI

let backgroundF = Color.clear

struct MainTabView: View {
    @StateObject private var inboxVM = InboxViewModel()
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
                .tabItem { Label("Find", systemImage: "magnifyingglass") }
                .tag(0)

            InboxView(viewModel: inboxVM)
                .tabItem { Label("Inbox", systemImage: selectedTab == 1 ? "tray.fill" : "tray") }
                .badge(inboxVM.unreadCount)
                .tag(1)

            CurrentUserProfileView()
                .tabItem { Label("Me", systemImage: selectedTab == 2 ? "person.fill" : "person") }
                .tag(2)
        }
        .tint(Color.nmaPrimary)
        .onAppear { inboxVM.startListening() }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
