//
//  ClerkSignInView.swift
//  coursiva
//
//  Created by Z1 on 15.06.2025.
//

import SwiftUI
import Clerk

struct ClerkSignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @Binding var errorMessage: String
    
    var body: some View {
        Text(localized: "Welcome back! Please sign in to continue")
            .bold()
            .foregroundColor(Color.appText)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
        
        VStack(spacing: 16) {
            CustomTextField(
                text: $email,
                placeholder: "Email",
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray, lineWidth: 0.5)
            }
            
            CustomTextField(
                text: $password,
                placeholder: "Password",
                isSecure: true,
                textContentType: .password
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray, lineWidth: 0.5)
            }
            
            Button {
                Task { await submit(email: email, password: password) }
            } label: {
                Text(localized: "Sign In")
            }
            .buttonStyle(PrimaryButtonStyle(isLoading: isLoading))

        }
        
    }
    
}

extension ClerkSignInView {
    func submit(email: String, password: String) async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await SignIn.create(
                strategy: .identifier(email.trimmingCharacters(in: .whitespacesAndNewlines), password: password.trimmingCharacters(in: .whitespacesAndNewlines))
            )
        } catch {
            errorMessage = "Invalid email or password. Please try again."
            dump(error)
        }
        
        isLoading = false
    }
} 
