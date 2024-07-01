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
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal, 24)
    }
    
    
    
}
