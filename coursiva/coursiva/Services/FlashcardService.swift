//
//  FlashcardService.swift
//  coursiva
//
//  Created by Z1 on 07.07.2025.
//

import Foundation

struct FlashcardService {
    static func fetchFlashcards(for videoUUID: String) async throws -> Flashcard {
        let jwt = try await APIClient.shared.getJWTToken()
        let flashcard: Flashcard = try await APIClient.shared.cachedRequest(endpoint: .getFlashcards(videoUUID: videoUUID), method: .get, token: jwt)
        return flashcard
    }

    static func generateFlashcards(for videoUUID: String) async throws -> Flashcard {
        let jwt = try await APIClient.shared.getJWTToken()
        let body = try JSONEncoder().encode(FlashcardRequestBody(video_uuid: videoUUID))
        return try await APIClient.shared.request(endpoint: .generateFlashcards(), method: .post, body: body, token: jwt)
    }
}
