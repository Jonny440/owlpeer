//
//  SocialSignInButton.swift
//  coursiva
//
//  Created by Z1 on 15.06.2025.
//

import SwiftUI

struct SocialSignInButton: View {
    let image: String
    let text: String
    
    var body: some View {
        Button {
            // Handle social sign in
        } label: {
            HStack {
                Image(systemName: image)
                Text(localized: text)
                    .font(.headline)
            }
            .foregroundColor(Color.appText)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.appBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appSecondary, lineWidth: 1)
            )
        }
    }
} 
