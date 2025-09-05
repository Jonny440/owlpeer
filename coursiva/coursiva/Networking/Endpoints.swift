//
//  Endpoints.swift
//  coursiva
//
//  Created by Z1 on 07.07.2025.
//

import Foundation

struct Endpoint {
    let path: String
    let queryParameters: [String: String]?
    
    init(path: String, queryParameters: [String: String]? = nil) {
        self.path = path
        self.queryParameters = queryParameters
    }
    
    var fullPath: String {
        guard let queryParameters = queryParameters, !queryParameters.isEmpty else {
            return path
        }
        let query = queryParameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        return "\(path)?\(query)"
    }
}

// MARK: - API Endpoints

extension Endpoint {
    
    // MARK: Course-related
    static func createCourse() -> Endpoint {
        .init(path: "create-course/")
    }

    static func myCourses() -> Endpoint {
        .init(path: "my-courses/")
    }

    static func courseDetails(uuid: UUID) -> Endpoint {
        .init(path: "playlists/\(uuid)/")
    }

    static func courseVideos(uuid: String) -> Endpoint {
        .init(path: "playlists/\(uuid)/videos/")
    }

    static func deleteCourse(uuid: String) -> Endpoint {
        .init(path: "my-courses/\(uuid)/delete/")
    }

    // MARK: Video-related
    static func videoDetails(uuid: String) -> Endpoint {
        .init(path: "videos/\(uuid)/")
    }

    static func deleteSingleVideo(uuid: String) -> Endpoint {
        .init(path: "my-single-videos/\(uuid)/delete/")
    }

    // MARK: Flashcards
    static func getFlashcards(videoUUID: String) -> Endpoint {
        .init(path: "flashcards/", queryParameters: ["video_uuid" : videoUUID])
    }

    static func generateFlashcards() -> Endpoint {
        .init(path: "flashcards/")
    }

    // MARK: MindMap
    static func getMindMap(videoUUID: UUID) -> Endpoint {
        .init(path: "mindmap/", queryParameters: ["video_uuid": videoUUID.uuidString])
    }

    static func generateMindMap(videoUUID: UUID) -> Endpoint {
        .init(path: "mindmap/")
    }

    // MARK: Quiz
    static func getQuiz(videoUUID: UUID) -> Endpoint {
        .init(path: "quiz/?video_uuid=\(videoUUID)")
    }

    static func generateQuiz() -> Endpoint {
        .init(path: "quiz/")
    }

    static func submitQuiz() -> Endpoint {
        .init(path: "quiz/submit/")
    }

    static func explainQuiz() -> Endpoint {
        .init(path: "quiz/explain/")
    }

    // MARK: AI Chat
    static func summaryChatbot() -> Endpoint {
        .init(path: "summary-chatbot/")
    }

    // MARK: Misc
    static func healthCheck() -> Endpoint {
        .init(path: "health/")
    }

    // MARK: Profile
    static func getProfile() -> Endpoint {
        .init(path: "auth/profile/")
    }
    static func updateProfile() -> Endpoint {
        .init(path: "auth/profile/")
    }
    
    //MARK: Delete User
    static func deleteUser() -> Endpoint {
        .init(path: "auth/delete/")
    }
    
    //MARK: Billing
    static func upgradeUser() -> Endpoint {
        .init(path: "payment/ios/webhook/")
    }
    
    //MARK: Recourcesc
    static func getRecources(videoUUID: String) -> Endpoint {
        .init(path: "perplexity/", queryParameters: ["video_uuid": videoUUID])
    }
    
    static func generateRecources() -> Endpoint {
        .init(path: "perplexity/")
    }
}
