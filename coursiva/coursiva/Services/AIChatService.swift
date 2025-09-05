//
//  AIChatService.swift
//  coursiva
//
//  Created by Z1 on 07.07.2025.
//

import Foundation

struct AIChatService {
    static func sendMessage(_ question: String, videoUUID: String) async throws -> String {
        let body = try JSONEncoder().encode(ChatMessageRequest(videoUUID: videoUUID, user_message: question))
        let jwt = try await APIClient.shared.getJWTToken()
        
        return try await APIClient.shared.requestRaw(
            endpoint: .summaryChatbot(),
            method: .post,
            body: body,
            token: jwt
        )
    }
}

