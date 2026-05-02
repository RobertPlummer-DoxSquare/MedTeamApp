//
//  TextFieldModifier.swift
//  MedTeam
//
//  Created by Robert Plummer on 6/24/24.
//

import SwiftUI

struct TextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .padding(14)
            .background(Color(white: 0.1))
            .cornerRadius(12)
            .padding(.horizontal, 24)
    }
}
