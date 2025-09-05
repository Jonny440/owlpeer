//
//  UIComponents.swift
//  coursiva
//
//  Created by Z1 on 16.06.2025.
//

import SwiftUI

struct CustomTextField: View {
    @Binding var text: String
    var placeholder: String? = nil
    var isSecure: Bool = false
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: UITextAutocapitalizationType = .none
    var backgroundColor: Color = Color.appSurface

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColor)
                .frame(height: 50)

            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.gray)
                }

                ZStack(alignment: .leading) {
                    if text.isEmpty, let placeholder = placeholder {
                        Text(localized: placeholder)
                            .foregroundColor(.gray)
                    }

                    if isSecure {
                        SecureField("", text: $text)
                            .keyboardType(keyboardType)
                            .textContentType(textContentType)
                            .autocapitalization(autocapitalization)
                            .foregroundColor(Color.appText)
                    } else {
                        TextField("", text: $text)
                            .keyboardType(keyboardType)
                            .textContentType(textContentType)
                            .autocapitalization(autocapitalization)
                            .foregroundColor(Color.appText)
                    }
                }
            }
            .padding(.horizontal, 12)
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.8)
                    .tint(.white)
            } else {
                configuration.label
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient.defaulGradient
                )
                .opacity(configuration.isPressed ? 0.8 : 1.0)
        )
        .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
        .foregroundColor(.white)
        .font(.headline)
        .disabled(isLoading)
        .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension Color {
    static let appSurface = Color("surfaceColor")
    static let appBackground = Color("backgroundColor")
    static let appText = Color("textColor")
}

extension LinearGradient {
    static var defaulGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0x7b/255.0, green: 0x3d/255.0, blue: 0xd8/255.0), // #7b3dd8
                Color(red: 0x57/255.0, green: 0x07/255.0, blue: 0xab/255.0)  // #5707ab
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
