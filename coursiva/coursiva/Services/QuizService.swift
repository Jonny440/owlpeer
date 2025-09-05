//
//  QuizService.swift
//  coursiva
//
//  Created by Z1 on 07.07.2025.
//

import Foundation

enum QuizServiceError: Error, Equatable {
    case quizNotFound
}

struct QuizService {
    static func getQuiz(videoUUID: String) async throws -> QuizResponse {
        let jwt = try await APIClient.shared.getJWTToken()
        let endpoint = Endpoint.getQuiz(videoUUID: UUID(uuidString: videoUUID) ?? UUID())
        let fullURL = URL(string: endpoint.fullPath, relativeTo: URL(string: "https://owlpeer.com/api/")!)!
        var request = URLRequest(url: fullURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Check for 'Quiz not found' message
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = json["message"] as? String,
           message.lowercased().contains("quiz not found") {
            throw QuizServiceError.quizNotFound
        }
        do {
            let quiz = try JSONDecoder().decode(QuizResponse.self, from: data)
            return quiz
        } catch {
            throw error
        }
    }
    
    static func generateQuiz(videoUUID: String) async throws -> QuizResponse {
        let jwt = try await APIClient.shared.getJWTToken()
        let body = try JSONSerialization.data(withJSONObject: ["video_uuid": videoUUID])
        return try await APIClient.shared.request(
            endpoint: .generateQuiz(),
            method: .post,
            body: body,
            token: jwt
        )
    }
    
    static func submitQuiz(quizUUID: String, answers: [Int]) async throws -> QuizSubmissionResponse {
        let jwt = try await APIClient.shared.getJWTToken()
        let requestBody = QuizSubmissionRequest(video_uuid : quizUUID, userAnswers: answers)
        let jsonData = try JSONEncoder().encode(requestBody)
        
        return try await APIClient.shared.request(
            endpoint: .submitQuiz(),
            method: .post,
            body: jsonData,
            token: jwt
        )
    }
    
    static func getQuizExplanation(question: String, userAnswer: String, correctAnswer: String, videoUUID: String) async throws -> QuizExplanationResponse {
        let jwt = try await APIClient.shared.getJWTToken()
        let requestBody = QuizExplanationRequest(
            question: question,
            userAnswer: userAnswer,
            correctAnswer: correctAnswer,
            videoUUID: videoUUID
        )
        let jsonData = try JSONEncoder().encode(requestBody)
        
        return try await APIClient.shared.request(
            endpoint: .explainQuiz(),
            method: .post,
            body: jsonData,
            token: jwt
        )
    }
}
