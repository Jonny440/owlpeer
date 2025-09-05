//
//  HomeViewModel.swift
//  coursiva
//
//  Created by Z1 on 07.07.2025.
//

import Foundation
import Clerk

@MainActor
class HomeViewModel: ObservableObject {
    //MARK: - Public Properties
    @Published var playlistURL: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String = ""
    @Published var successMessage: String = ""

    //MARK: - Init
    init() {}

    //MARK: - Public Methods
    func createCourse() async {
        isLoading = true
        errorMessage = ""
        successMessage = ""
        let trimmedURL = playlistURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else {
            errorMessage = "Please enter a YouTube URL"
            isLoading = false
            return
        }
        do {
            let _ = try await CourseService.createCourse(from: trimmedURL)
            successMessage = "Course created successfully"
            playlistURL = ""
        } catch {
            if let apiError = error as? NetworkError {
                errorMessage = "Error: \(apiError.localizedDescription)"
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }

    //MARK: - Private Methods
    // (none)
}
