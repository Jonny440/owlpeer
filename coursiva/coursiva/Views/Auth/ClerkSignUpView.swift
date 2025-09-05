//
//  ClerkSignUpView.swift
//  coursiva
//
//  Created by Z1 on 15.06.2025.
//

import SwiftUI
import Clerk

struct ClerkSignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var code = ""
    @State private var isVerifying = false
    @State private var isLoading = false
    @Binding var errorMessage: String
    
    var body: some View {
        Text(localized: "Please fill in the details to get started")
            .bold()
            .foregroundColor(Color.appText)
        
        if isVerifying {
            VStack(spacing: 16) {
                Text(localized: "Check your email")
                    .font(.headline)
                    .foregroundColor(Color.text)
                
                Text(String(format: NSLocalizedString("We sent a verification code to %@", comment: ""), email))
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                CustomTextField(
                    text: $code,
                    placeholder: "Verification Code",
                    keyboardType: .numberPad
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray, lineWidth: 0.5)
                }
                
                Button("Verify") {
                    Task { await verify(code: code) }
                }
                .buttonStyle(PrimaryButtonStyle(isLoading: isLoading))
            }
        } else {
            VStack(spacing: 16) {
                CustomTextField(
                    text: $email,
                    placeholder:  "Email".localized,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray, lineWidth: 0.5)
                }
                
                CustomTextField(
                    text: $password,
                    placeholder:  "Password".localized,
                    isSecure: true,
                    textContentType: .newPassword
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray, lineWidth: 0.5)
                }
                
                Button("Create Account".localized) {
                    Task { await signUp(email: email, password: password) }
                }
                .buttonStyle(PrimaryButtonStyle(isLoading: isLoading))
                
                
            }
        }
        
    }
}

extension ClerkSignUpView {
    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = ""
        
        do {
            let signUp = try await SignUp.create(
                strategy: .standard(emailAddress: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password.trimmingCharacters(in: .whitespacesAndNewlines))
            )

            try await signUp.prepareVerification(strategy: .emailCode)
            isVerifying = true
        } catch let apiError as ClerkAPIError {
            errorMessage = apiError.message ?? "Sign up failed. Please try again."
            dump(apiError)
        } catch {
            errorMessage = "Sign up failed. Please try again."
            dump(error)
        }
        
        isLoading = false
    }

    func verify(code: String) async {
        isLoading = true
        errorMessage = ""
        
        do {
            guard let signUp = Clerk.shared.client?.signUp else {
                isVerifying = false
                errorMessage = "Something went wrong. Please try again."
                isLoading = false
                return
            }

            try await signUp.attemptVerification(strategy: .emailCode(code: code))
        } catch {
            errorMessage = "Invalid verification code. Please try again."
            dump(error)
        }
        
        isLoading = false
    }
} 
