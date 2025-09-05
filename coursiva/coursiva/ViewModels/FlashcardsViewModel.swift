import Foundation
import SwiftUI

@MainActor
class FlashcardsViewModel: ObservableObject {
    //MARK: - Public Properties
    @Published var state: State = .loading
    @Published var currentCardIndex: Int = 0
    @Published var isGenerating: Bool = false
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
                let flashcards = try await FlashcardService.fetchFlashcards(for: id.uuidString.lowercased()).flashcards
                if flashcards.isEmpty {
                    self.state = .noFlashcards
                } else {
                    self.state = .loaded(flashcards)
                    self.currentCardIndex = 0
                }
            } catch {
                self.state = .noFlashcards
            }
        }
    }

    func nextCard() {
        if case .loaded(let flashcards) = state, currentCardIndex < flashcards.count - 1 {
            currentCardIndex += 1
        }
    }

    func previousCard() {
        if currentCardIndex > 0 {
            currentCardIndex -= 1
        }
    }

    func generateFlashcards() {
        isGenerating = true
        self.state = .loading
        Task {
            do {
                _ = try await FlashcardService.generateFlashcards(for: id.uuidString.lowercased())
                await MainActor.run {
                    self.isGenerating = false
                    self.fetch()
                }
            } catch {
                await MainActor.run {
                    self.isGenerating = false
                    self.state = .error(error)
                }
            }
        }
    }

    //MARK: - Private Methods
    
    enum State {
        case loading
        case loaded([FlashcardItem])
        case error(Error)
        case noFlashcards
    }
}
