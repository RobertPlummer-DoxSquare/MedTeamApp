//
//  TextFieldModifier.swift
//  MedTeam
//

import SwiftUI

struct TextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .foregroundColor(.nmaPrimary)
            .padding(14)
            .background(Color.nmaSurface)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.nmaBorder, lineWidth: 0.5))
            .tint(.nmaPrimary)
            // The field is always white, so use light-mode text and placeholder colors
            // even on screens that force dark mode.
            .environment(\.colorScheme, .light)
            .padding(.horizontal, 24)
    }
}
