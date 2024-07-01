//
//  Hamburger.swift
//  MedTeam
//
//  Created by Robert Plummer on 6/25/24.
//

import SwiftUI

struct Hamburger: View {
    @Binding var showHamburger: Bool
    @State private var showSideMenu = true
    @EnvironmentObject var authService: AuthService

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 45) {
                    if !showHamburger {
                        HamburgerButton(showMenu: $showHamburger)
                    }
                    TabButton(title: "Home", image: "Profile") {
                        showHamburger = false
                    }
//                    TabButton(title: "Login", image: "Profile") {
//                        self.showSideMenu = true
//                    }
                    TabButton(title: "Logout", image: "Profile") {
                        authService.signOut()
                        showHamburger = false
                    }
                    .colorScheme(.light)
                }
                .padding()
                .padding(.leading)
                .padding(.top, 115)
                .padding(.leading, -40)
            }
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(width: getRect().width - 90)
        .frame(maxHeight: .infinity)
        .background(
            Color.primary
                .opacity(0.04)
                .ignoresSafeArea(.container, edges: .vertical)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HamburgerButton: View {
    @Binding var showMenu: Bool

    var body: some View {
        if showMenu {
            EmptyView()
        } else {
            Button(action: {
                showMenu.toggle()
                hide(showMenu: $showMenu)
            }) {
                Image(systemName: "line.horizontal.3")
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .medium))
            }
        }
    }
}

@ViewBuilder
func TabButton(title: String, image: String, action: @escaping () -> Void = {})-> some View {
    Button(action: action)  {
        HStack(spacing: 14) {
            Image(image)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fill)
                .frame(width: 22, height: 22)
            Text(title)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .accentColor(.white)
}

func hide(showMenu: Binding<Bool>) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        showMenu.wrappedValue = true
    }
}

extension View {
    func getRect() -> CGRect {
        return UIScreen.main.bounds
    }
}

struct Hamburger_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//

//extension View {
//    func getRect()-> CGRect{
//        return UIScreen.main.bounds
//    }
//}

extension View {
    static func fromUIColor(_ uiColor: UIColor) -> Color {
        return Color(uiColor)
    }
}

