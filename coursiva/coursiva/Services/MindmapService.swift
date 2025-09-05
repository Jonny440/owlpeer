//
//  MindMapService.swift
//  coursiva
//
//  Created by Z1 on 07.07.2025.
//

import Foundation

struct MindMapService {
    static func getMindMap(videoUUID: UUID) async throws -> MindMapResponse {
        let jwt = try await APIClient.shared.getJWTToken()
        return try await APIClient.shared.request(endpoint: .getMindMap(videoUUID: videoUUID), method: .get, token: jwt)
    }
    
    static func generateMindMap(videoUUID: UUID) async throws -> MindMapResponse {
        let jwt = try await APIClient.shared.getJWTToken()
        return try await APIClient.shared.request(endpoint: .generateMindMap(videoUUID: videoUUID), method: .post, token: jwt)
    }
}

