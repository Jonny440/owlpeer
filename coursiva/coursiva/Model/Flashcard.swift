//
//  Flashcard.swift
//  coursiva
//
//  Created by Z1 on 15.06.2025.
//
import Foundation

//MARK: - fetchFlashcards() Response Body
struct Flashcard: Identifiable, Codable {
    let id: String
    let flashcards: [FlashcardItem]
    let videoTitle: String

    enum CodingKeys: String, CodingKey {
        case id = "uuid_flashcard"
        case flashcards
        case videoTitle = "video_title"
    }
}

struct FlashcardItem: Codable {
    let question: String
    let answer: String
}

//MARK: - generateFlashcards() Request Body
struct FlashcardRequestBody: Codable {
    let video_uuid: String
}
