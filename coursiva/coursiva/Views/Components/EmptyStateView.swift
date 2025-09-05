//
//  ResourcesEmptyStateView.swift
//  coursiva
//
//  Created by AI Assistant on 02.09.2025.
//

import SwiftUI

struct EmptyStateView: View {
    let iconName: String
    let title: String
    let message: String
    let buttonTitle: String
    let isLoading: Bool
    let action: () -> Void

    init(
        iconName: String = "doc.text.magnifyingglass",
        title: String,
        message: String,
        buttonTitle: String,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.iconName = iconName
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: iconName)
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.8))

            Text(localized: title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(localized: message)
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                if !isLoading {
                    action()
                }
            } label: {
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    Text(localized: buttonTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .buttonStyle(PrimaryButtonStyle(isLoading: isLoading))
            .disabled(isLoading)

            Spacer()
        }
        .padding(.horizontal, 20)
    }
}


