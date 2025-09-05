//
//  RecourcesService.swift
//  coursiva
//
//  Created by Z1 on 29.08.2025.
//

import Foundation

struct RecourcesService {
    static func fetchRecources(for videoUUID: String) async throws -> Resources {
        let jwt = try await APIClient.shared.getJWTToken()
        
        do {
            let recources: Resources = try await APIClient.shared.cachedRequest(endpoint: .getRecources(videoUUID: videoUUID), method: .get, token: jwt)
            return recources
        } catch {
            // Check if it's a 404 response that we can handle
            if let networkError = error as? NetworkError,
               case .invalidResponse(let statusCode) = networkError,
               statusCode == 404 {
                
                // Return a Recources object with the error message
                return Resources(
                    title: nil,
                    summary: nil,
                    recourcesMarkdown: nil,
                    updatedAt: nil,
                    error: "No resources found for this video"
                )
            }
            
            // Re-throw other errors
            throw error
        }
    }

    static func generateRecources(for videoUUID: String) async throws -> Resources {
        let jwt = try await APIClient.shared.getJWTToken()
        let body = try JSONEncoder().encode(["video_uuid": videoUUID])
        
        let recources: Resources = try await APIClient.shared.request(endpoint: .generateRecources(), method: .post, body: body, token: jwt)
        return recources
    }
}

