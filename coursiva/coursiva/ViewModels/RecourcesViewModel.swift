//
//  RecourcesViewModel.swift
//  coursiva
//
//  Created by Z1 on 29.08.2025.
//
import Foundation

@MainActor
class RecourcesViewModel: ObservableObject {
    private let id: UUID
    @Published var state: State = .loading
    
    init(id: UUID) {
        self.id = id
    }
    
    func fetch() async {
        state = .loading
        
        do {
            let recources = try await RecourcesService.fetchRecources(for: id.uuidString)
            
            if let error = recources.error {
                if error == "No resources found for this video" {
                    self.state = .noRecources
                } else {
                    self.state = .error(error)
                }
            } else {
                self.state = .loaded(recources)
            }
        } catch {
            self.state = .noRecources
        }
    }
    
    func generateRecources() {
        state = .loading
        Task {
            do {
                let recources = try await RecourcesService.generateRecources(for: id.uuidString)
                
                if let error = recources.error {
                    self.state = .error(error)
                } else {
                    self.state = .loaded(recources)
                }
            } catch {
                self.state = .error(error.localizedDescription)
            }
        }
    }

    //MARK: - Private Methods
    enum State {
        case loading
        case loaded(Resources)
        case error(String)
        case noRecources
    }
}
