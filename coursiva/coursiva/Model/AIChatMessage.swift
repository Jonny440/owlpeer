//
//  AIChatMessage.swift
//  coursiva
//
//  Created by Z1 on 09.07.2025.
//
import Foundation

//MARK: - sendMessage() Response Body
struct ChatMessageResponse: Codable {
    let answer: String
    let videoTitle: String
    
    enum CodingKeys: String, CodingKey {
        case answer
        case videoTitle = "video_title"
    }
}

//MARK: - sendMessage() Request Body
struct ChatMessageRequest: Codable {
    let videoUUID: String
    let user_message: String
    
    enum CodingKeys: String, CodingKey {
        case videoUUID = "video_uuid"
        case user_message
    }
}
