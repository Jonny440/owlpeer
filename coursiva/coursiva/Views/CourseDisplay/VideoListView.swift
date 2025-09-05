//
//  VideoDetailView.swift
//  coursiva
//
//  Created by Z1 on 16.06.2025.
//

import SwiftUI
import Kingfisher

struct VideoListView: View {
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible())
    ]
    let playlistID: UUID
    let title: String
    @StateObject private var viewModel: VideoListViewModel
    
    init(playlistID: UUID, title: String) {
        self.playlistID = playlistID
        self._viewModel = StateObject(wrappedValue: VideoListViewModel())
        self.title = title
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.isLoading {
                    ProgressView("Loading videos...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .padding()
                } else if viewModel.errorMessage != "" {
                    VStack(spacing: 16) {
                        Text(localized: "Error")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(localized: viewModel.errorMessage)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            Task {
                                await viewModel.fetchVideos(for: playlistID)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .padding()
                } else if !viewModel.videos.isEmpty {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.videos) { video in
                            PlaylistVideoCardView(
                                id: video.id,
                                title: video.title,
                                thumbnailURL: video.thumbnail
                            )
                        }
                    }
                    .padding()
                } else {
                    VStack {
                        Text(localized: "No videos found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .padding()
                }
            }
        }
        .navigationTitle(title)
        .background(Color.appBackground)
        .task {
            await viewModel.fetchVideos(for: playlistID)
        }
    }
}
