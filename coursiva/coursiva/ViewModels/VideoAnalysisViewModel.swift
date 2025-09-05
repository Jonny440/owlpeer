import Foundation
import SwiftUI

@MainActor
class VideoAnalysisViewModel: ObservableObject {
    //MARK: - Public Properties
    @Published var seekToTime: Double? = nil
    @Published var state: State = .loading
    let id: UUID

    //MARK: - Init
    init(id: UUID) {
        self.id = id
    }

    //MARK: - Public Methods
    func fetch() {
        state = .loading
        Task {
            do {
                let video = try await VideoService.fetchVideoDetails(uuid: id.uuidString.lowercased())
                self.state = .loaded(video)
            } catch {
                self.state = .error(error)
            }
        }
    }

    //MARK: - Private Methods
    // (none)
    
    enum State {
        case loading
        case loaded(Video)
        case error(Error)
    }
} 
