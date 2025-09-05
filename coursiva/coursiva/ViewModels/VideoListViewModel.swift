//
//  VideoListViewModel.swift
//  coursiva
//
//  Created by Z1 on 07.07.2025.
//

import Foundation

@MainActor
class VideoListViewModel: ObservableObject {
    //MARK: - Public Properties
    @Published var videos: [VideoListItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""

    //MARK: - Init
    init() {}

    //MARK: - Public Methods
    func fetchVideos(for playlistUUID: UUID) async {
        isLoading = true
        errorMessage = ""
        do {
            let videoList = try await VideoService.fetchLightweightVideos(for: playlistUUID)
            self.videos = videoList.videos
        } catch {
            errorMessage = "Failed to load videos"
        }
        isLoading = false
    }

    //MARK: - Private Methods
    // (none)
} 
