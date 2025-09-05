//
//  SafeKFImage.swift
//  coursiva
//
//  Created by Z1 on 30.07.2025.
//


import SwiftUI
import Kingfisher

struct SafeKFImage: View {
    @State private var url: URL
    let originalURL: URL?
    let aspectRatio: CGFloat

    init(url: URL?, aspectRatio: CGFloat = 16/9) {
        self.originalURL = url
        _url = State(initialValue: url ?? .defaultUnavailableImage)
        self.aspectRatio = aspectRatio
    }

    var body: some View {
        // Create a container with fixed aspect ratio
        Rectangle()
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay(
                KFImage(url)
                    .onFailure { _ in
                        if url != .defaultUnavailableImage {
                            url = .defaultUnavailableImage
                        }
                    }
                    .placeholder {
                        // Optional: Add a loading placeholder
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.8)
                            )
                    }
                    .resizable()
                    .scaledToFill()
            )
            .clipped()
            .cornerRadius(10)
    }
}

extension URL {
    static let defaultUnavailableImage = URL(string: "https://images.drivereasy.com/wp-content/uploads/2017/10/this-video-is-not-available-1.jpg")!
}
