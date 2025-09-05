//
//  Quiz.swift
//  coursiva
//
//  Created by Z1 on 15.06.2025.
//
import Foundation

// MARK: - Quiz API Request/Response Models

// Used in: QuizService.submitQuiz()
struct QuizSubmissionRequest: Codable {
    let video_uuid: String
    let userAnswers: [Int]
    
    enum CodingKeys: String, CodingKey {
        case video_uuid
        case userAnswers = "user_answers"
    }
}

// Used in: QuizService.submitQuiz()
struct QuizSubmissionResponse: Codable {
    let message: String
    let results: QuizResults
    
    struct QuizResults: Codable {
        let totalQuestions: Int
        let correctAnswers: Int
        let scorePercentage: Float
        let isCompleted: Bool
        let completedAt: String
        let userAnswers: [UserAnswerResult]
        
        enum CodingKeys: String, CodingKey {
            case totalQuestions = "total_questions"
            case correctAnswers = "correct_answers"
            case scorePercentage = "score_percentage"
            case isCompleted = "is_completed"
            case completedAt = "completed_at"
            case userAnswers = "user_answers"
        }
    }
    
    // Computed properties for backward compatibility
    var score: Float { results.scorePercentage }
    var correctAnswers: Int { results.correctAnswers }
    var totalQuestions: Int { results.totalQuestions }
    var feedback: String { message }
}

// Used in: QuizSubmissionResponse.QuizResults.userAnswers
struct UserAnswerResult: Codable {
    let questionIndex: Int
    let selectedAnswer: Int
    let isCorrect: Bool
    let correctAnswer: Int
    
    enum CodingKeys: String, CodingKey {
        case questionIndex = "question_index"
        case selectedAnswer = "selected_answer"
        case isCorrect = "is_correct"
        case correctAnswer = "correct_answer"
    }
}

// MARK: - Quiz Explanation API Models

// Used in: getQuizExplanation()
struct QuizExplanationRequest: Codable {
    let question: String
    let userAnswer: String
    let correctAnswer: String
    let videoUUID: String
    
    enum CodingKeys: String, CodingKey {
        case question
        case userAnswer = "user_answer"
        case correctAnswer = "correct_answer"
        case videoUUID = "video_uuid"
    }
}

// Used in: getQuizExplanation()
struct QuizExplanationResponse: Codable {
    let explanation: String
}

//MARK: - Main Quiz Response
struct QuizResponse: Codable {
    let message: String?
    let quiz: Quiz?
    let videoTitle: String?
    let created: Bool?
    let partialProgress: PartialProgress?

    enum CodingKeys: String, CodingKey {
        case message, quiz
        case videoTitle = "video_title"
        case created
        case partialProgress = "partial_progress"
    }
}

struct PartialProgress: Codable {
    let partialAnswers: [String: Int]
    let aiExplanations: [String: String]
    let revealedAnswers: [String: Bool]
    let answeredQuestionsCount: Int
    let hasProgress: Bool

    enum CodingKeys: String, CodingKey {
        case partialAnswers = "partial_answers"
        case aiExplanations = "ai_explanations"
        case revealedAnswers = "revealed_answers"
        case answeredQuestionsCount = "answered_questions_count"
        case hasProgress = "has_progress"
    }
}

struct UserAnswer: Codable {
    let isCorrect: Bool
    let correctAnswer: Int
    let questionIndex: Int
    let selectedAnswer: Int
    
    enum CodingKeys: String, CodingKey {
        case isCorrect = "is_correct"
        case correctAnswer = "correct_answer"
        case questionIndex = "question_index"
        case selectedAnswer = "selected_answer"
    }
}

struct Quiz: Identifiable, Codable {
    let id: Int
    let uuid: String?
    let quizJSON: [QuizQuestion]
    let questionsCount: Int?
    let quizDurationSeconds: Int?
    let userID: Int?
    let videoID: Int?
    let createdAt: String?
    let isCompleted: Bool?
    let scorePercentage: Float?
    let correctAnswersCount: Int?
    let userAnswers: [UserAnswer]?
    let partialAnswers: [String: Int]?
    let aiExplanations: [String: String]?
    let revealedAnswers: [String: Bool]?
    let answeredQuestionsCount: Int?
    let hasPartialProgress: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case uuid
        case quizJSON = "quiz_json"
        case questionsCount = "questions_count"
        case quizDurationSeconds = "quiz_duration_seconds"
        case userID = "user"
        case videoID = "quiz_video"
        case createdAt = "created_at"
        case isCompleted = "is_completed"
        case scorePercentage = "score_percentage"
        case correctAnswersCount = "correct_answers_count"
        case userAnswers = "user_answers"
        case partialAnswers = "partial_answers"
        case aiExplanations = "ai_explanations"
        case revealedAnswers = "revealed_answers"
        case answeredQuestionsCount = "answered_questions_count"
        case hasPartialProgress = "has_partial_progress"
    }
}

struct QuizQuestion: Codable {
    let question: String
    let answers: [String]
    let correctAnswer: Int

    enum CodingKeys: String, CodingKey {
        case question, answers
        case correctAnswer = "correct_index"
    }
}
