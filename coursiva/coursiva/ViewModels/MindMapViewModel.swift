//
//  MindMapViewModel.swift
//  coursiva
//
//  Created by Z1 on 07.07.2025.
//

import Foundation

@MainActor
class MindMapViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var mindmapData: MindMapRootWrapper?
    @Published var videoTitle: String = ""
    @Published var isLoading: Bool = false
    @Published var isGenerating: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let videoUUID: UUID
    
    // MARK: - State Enum
    enum State {
        case loading
        case loaded(MindMapRootWrapper)
        case error(String)
        case noMindMap
    }
    
    @Published var state: State = .loading
    
    // MARK: - Init
    init(videoUUID: UUID) {
        self.videoUUID = videoUUID
    }
    
    // MARK: - Public Methods
    func fetch() async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await MindMapService.getMindMap(videoUUID: videoUUID)
            
            // Check if the response message indicates no mindmap found
            if response.message.contains("No mindmap found for this video") {
                state = .noMindMap
                isLoading = false
                return
            }
            
            let mindmap = response.mindmap
            mindmapData = mindmap
            videoTitle = response.video_title
            
            if let mindmap = mindmapData {
                state = .loaded(mindmap)
            } else {
                state = .noMindMap
            }
        } catch {
            if let networkError = error as? NetworkError {
                switch networkError {
                case .serverError(statusCode: 404):
                    state = .noMindMap
                default:
                    state = .error(networkError.localizedDescription)
                    errorMessage = networkError.localizedDescription
                }
            } else {
                state = .error(error.localizedDescription)
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }
    
    func generateMindMap() async {
        isGenerating = true
        errorMessage = nil

        do {
            let response = try await MindMapService.generateMindMap(videoUUID: videoUUID)
            
            mindmapData = response.mindmap
            videoTitle = response.video_title
            
            if let mindmap = mindmapData {
                state = .loaded(mindmap)
            } else {
                state = .noMindMap
            }
        } catch {
            state = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
        }

        isGenerating = false
    }
}
