//
//  CourseCardView.swift
//  coursiva
//
//  Created by Z1 on 15.06.2025.
//

import SwiftUI
import Kingfisher

struct CourseCardView: View {
    let id: UUID
    let title: String
    let thumbnailURL: URL?
    @State private var isDeleting = false
    var onDelete: (() async -> Void)?

    
    var body: some View {
        NavigationLink(destination: VideoListView(playlistID: id, title: title)) {
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
                                    try await CourseService.deleteCourse(uuid: id)
                                    if let onDelete = onDelete {
                                        await onDelete()
                                    }
                                } catch {
                                    print("Failed to delete course: \(error)")
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
