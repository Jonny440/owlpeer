//
//  AuthTextField.swift
//  coursiva
//
//  Created by Z1 on 15.06.2025.
//

import SwiftUI
import RevenueCat

struct AuthTextField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localized: title)
                .font(.subheadline)
                .foregroundColor(Color.appText)
            
            if isSecure {
                SecureField("", text: $text)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.appBackground)
                    .cornerRadius(8)
            } else {
                TextField("", text: $text)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.appBackground)
                    .cornerRadius(8)
            }
        }
    }
} 

extension Purchases {
    static var isProUser: Bool {
        get async {
            do {
                let customerInfo = try await Purchases.shared.customerInfo()
                // Replace "pro" with your entitlement identifier from RevenueCat dashboard
                return customerInfo.entitlements["pro"]?.isActive == true
            } catch {
                print("Failed to fetch customer info: \(error)")
                return false
            }
        }
    }
}
