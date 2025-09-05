//
//  VideoCardView.swift
//  coursiva
//
//  Created by Z1 on 08.07.2025.
//

import SwiftUI
import Kingfisher

struct VideoCardView: View {
    let id: UUID
    let title: String
    let thumbnailURL: URL?
    var onDelete: (() async -> Void)?
    @State private var isDeleting = false
    @State private var fallback = false
    
    var body: some View {
        NavigationLink(destination: VideoDetailView(id: id, title: title, thumbnail: thumbnailURL)) {
            VStack(alignment: .leading, spacing: 8) {
                SafeKFImage(url: thumbnailURL)

                HStack {
                    Text(localized: title)
                        .foregroundColor(Color.text)
                        .font(.callout)
                        .lineLimit(1)
                    Spacer()
                    
                    Menu {
                        Button(role: .destructive) {
                            isDeleting = true
                            Task {
                                do {
                                    try await VideoService.deleteSingleVideo(uuid: id)
                                    if let onDelete = onDelete {
                                        await onDelete()
                                    }
                                } catch {
                                    print("Failed to delete video: \(error)")
                                }
                                isDeleting = false
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.gray)
                    }
                    .disabled(isDeleting)
                    
                }
                .padding(.horizontal, 4)
            }
            .padding(7)
            .background(Color("surfaceColor"))
            .cornerRadius(16)
        }
    }
}
