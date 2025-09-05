//
//  ClerkAuthView.swift
//  coursiva
//
//  Created by Z1 on 15.06.2025.
//

import SwiftUI
import Clerk
import AuthenticationServices

struct ClerkAuthView: View {
    @State private var isSignUp = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // App branding
                VStack(alignment: .center, spacing: 8) {
                    Image("logo_icon_text")
                        .resizable()
                        .scaledToFit()
                        .frame(width: UIScreen.main.bounds.width * 0.65)
                        .padding(.horizontal)
                    
                    Text(localized: isSignUp ? "Create your account" : "Sign in to your account")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Auth content
                VStack(spacing: 24) {
                    if isSignUp {
                        ClerkSignUpView(errorMessage: $errorMessage)
                    } else {
                        ClerkSignInView(errorMessage: $errorMessage)
                    }
                    Button(action:{
                        isSignUp.toggle()
                    }) {
                        let string = isSignUp ? "Already have an account? **Sign in**" : "Don't have an account? **Sign up**"
                        Text(localized: string)
                            .foregroundColor(Color.appText)
                    }
                    if !errorMessage.isEmpty {
                        Text(localized: errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal)
                .cornerRadius(16)
                .shadow(radius: 8)
                .padding(.horizontal)

                // Divider and social buttons
                VStack(spacing: 16) {
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                        Text(localized: "or")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.3))
                    }
                    
                    // Apple Sign In Button
                    Button(action: {
                        Task { await signInWithApple() }
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "applelogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(Color.white)
                            Text(localized: "Continue with Apple")
                                .foregroundStyle(Color.appText)
                            Spacer()
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                    }
                    
                    // Google Sign In/Up Button
                    Button(action: {
                        Task { await signInWithGoogle() }
                    }) {
                        HStack {
                            Spacer()
                            Image("g")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                            Text(localized: "Continue with Google")
                                .foregroundStyle(Color.appText)
                            Spacer()
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.horizontal)
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .gesture(
            DragGesture().onChanged { _ in
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        )
    }
}

extension ClerkAuthView {
    
    func signInWithGoogle() async {
        do {
            try await SignIn.authenticateWithRedirect(strategy: .oauth(provider: .google))
        } catch {
            let authError = error as NSError
            if authError.domain == "com.apple.AuthenticationServices.WebAuthenticationSession", authError.code == 1 { // user canceled
                return
            } else if authError.domain == "com.apple.AuthenticationServices.AuthorizationError" {
                return
            }
            errorMessage = error.localizedDescription
        }
    }
    
    func signInWithApple() async {
        do {
            let appleIdCredential = try await SignInWithAppleHelper.getAppleIdCredential()
            guard let idToken = appleIdCredential.identityToken.flatMap({ String(data: $0, encoding: .utf8) }) else { return }
            try await SignIn.authenticateWithIdToken(provider: .apple, idToken: idToken)
        } catch {
            if let error = error as? ASAuthorizationError, error.code == .canceled { return }
            errorMessage = error.localizedDescription
        }
    }
}
