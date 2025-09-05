//
//  QuizViewModel.swift
//  coursiva
//
//  Created by Z1 on 07.07.2025.
//

import Foundation
import SwiftUI

@MainActor
class QuizViewModel: ObservableObject {
    enum QuizState {
        case loading
        case loaded(Quiz)
        case error(Error)
        case noQuiz
        case alreadyCompleted(Quiz)
    }
    //MARK: - Public Properties
    @Published var state: QuizState = .loading
    @Published var currentIndex = 0
    @Published var selectedAnswers: [Int?] = []
    @Published var showingExplanation = false
    @Published var explanation: String = ""
    @Published var aiExplanations: [String: String] = [:]
    @Published var revealedAnswers: [String: Bool] = [:]
    @Published var isSubmitting = false
    @Published var isLoadingAIExplanation = false

    //MARK: - Private Properties
    private let videoUUID: String
    private var quizUUID: String?

    //MARK: - Init
    init(videoUUID: String) {
        self.videoUUID = videoUUID
    }

    //MARK: - Public Methods
    var questions: [QuizQuestion] {
        switch state {
        case .loaded(let quiz), .alreadyCompleted(let quiz):
            return quiz.quizJSON
        default:
            return []
        }
    }
    
    var currentQuestion: QuizQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    var isLastQuestion: Bool {
        currentIndex == questions.count - 1
    }
    
    var canProceed: Bool {
        selectedAnswers.indices.contains(currentIndex) && selectedAnswers[currentIndex] != nil
    }
    
    var canSubmit: Bool {
        guard case .loaded = state else {
            return false 
        }
        let allAnswered = selectedAnswers.count == questions.count && selectedAnswers.allSatisfy { $0 != nil }
        let onLastQuestion = isLastQuestion
        let result = allAnswered && onLastQuestion
        return result
    }
    
    var progress: Float {
        guard !questions.isEmpty else { return 0 }
        return Float(currentIndex + 1) / Float(questions.count)
    }
    
    var hasPartialProgress: Bool {
        switch state {
        case .loaded(let quiz), .alreadyCompleted(let quiz):
            return quiz.hasPartialProgress == true
        default:
            return false
        }
    }
    
    var isQuizCompleted: Bool {
        switch state {
        case .alreadyCompleted:
            return true
        default:
            return false
        }
    }
    
    func getAIExplanation(for questionIndex: Int) -> String? {
        return aiExplanations[String(questionIndex)]
    }
    
    func isAnswerRevealed(for questionIndex: Int) -> Bool {
        return revealedAnswers[String(questionIndex)] == true
    }
    
    func loadQuiz() {
        state = .loading
        Task {
            do {
                let response = try await QuizService.getQuiz(videoUUID: videoUUID)
                guard let quiz = response.quiz else { return }
                if !quiz.quizJSON.isEmpty {
                    await MainActor.run {
                        self.quizUUID = quiz.uuid
                        self.selectedAnswers = Array(repeating: nil, count: quiz.quizJSON.count)
                        
                        // Restore partial progress if available
                        if let partialProgress = response.partialProgress {
                            self.aiExplanations = partialProgress.aiExplanations
                            self.revealedAnswers = partialProgress.revealedAnswers
                        }
                        
                        // Restore user's previous answers from userAnswers array
                        if let userAnswers = quiz.userAnswers {
                            for userAnswer in userAnswers {
                                let questionIndex = userAnswer.questionIndex
                                if questionIndex < quiz.quizJSON.count {
                                    self.selectedAnswers[questionIndex] = userAnswer.selectedAnswer
                                }
                            }
                        }
                        
                        // Check if quiz is already completed
                        if quiz.isCompleted == true {
                            self.state = .alreadyCompleted(quiz)
                        } else {
                            self.state = .loaded(quiz)
                        }
                    }
                } else {
                    await MainActor.run {
                        self.state = .noQuiz
                    }
                }
            } catch let error as QuizServiceError {
                if error == .quizNotFound {
                    await MainActor.run {
                        self.state = .noQuiz
                    }
                } else {
                    await MainActor.run {
                        self.state = .error(error)
                    }
                }
            } catch {
                await MainActor.run {
                    self.state = .error(error)
                }
            }
        }
    }
    
    func generateQuiz() {
        state = .loading
        Task {
            do {
                let response = try await QuizService.generateQuiz(videoUUID: videoUUID)
                
                await MainActor.run {
                    if let quiz = response.quiz, !quiz.quizJSON.isEmpty {
                        self.selectedAnswers = Array(repeating: nil, count: quiz.quizJSON.count)
                        self.quizUUID = quiz.uuid
                        self.state = .loaded(quiz)
                    } else {
                        self.state = .noQuiz
                    }
                }
            } catch {
                await MainActor.run {
                    self.state = .error(error)
                }
            }
        }
    }
    
    func selectAnswer(_ answerIndex: Int) {
        guard currentIndex < selectedAnswers.count else { return }
        selectedAnswers[currentIndex] = answerIndex
    }
    
    func submitQuiz() {
        guard canSubmit else { return }
        
        let answers = selectedAnswers.compactMap { $0 }
        isSubmitting = true
        
        Task {
            do {
                _ = try await QuizService.submitQuiz(quizUUID: videoUUID, answers: answers)
                
                await MainActor.run {
                    self.isSubmitting = false
                    self.currentIndex = 0
                    // After successful submission, reload the quiz to get updated completion status
                    self.loadQuiz()
                }
            } catch {
                
                await MainActor.run {
                    self.state = .error(error)
                    self.isSubmitting = false
                }
            }
        }
    }
    
    func requestAIExplanation() {
        guard let question = currentQuestion, let selected = selectedAnswers[currentIndex] else { return }
        
        isLoadingAIExplanation = true
        let questionText = question.question
        let userAnswer = question.answers[selected]
        let correctAnswer = question.answers[question.correctAnswer]
        
        Task {
            do {
                let response = try await QuizService.getQuizExplanation(
                    question: questionText,
                    userAnswer: userAnswer,
                    correctAnswer: correctAnswer,
                    videoUUID: videoUUID
                )
                await MainActor.run {
                    self.aiExplanations[String(self.currentIndex)] = response.explanation
                    self.revealedAnswers[String(self.currentIndex)] = true
                    self.isLoadingAIExplanation = false
                }
            } catch {
                await MainActor.run {
                    self.aiExplanations[String(self.currentIndex)] = "Failed to load explanation: \(error.localizedDescription)"
                    self.revealedAnswers[String(self.currentIndex)] = true
                    self.isLoadingAIExplanation = false
                }
            }
        }
    }
    
    func nextQuestion() {
        guard currentIndex < questions.count - 1 else { return }
        currentIndex += 1
    }
    
    func previousQuestion() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }
    
    func getExplanation() {
        guard let question = currentQuestion, let selected = selectedAnswers[currentIndex] else { return }
        
        let questionText = question.question
        let userAnswer = question.answers[selected]
        let correctAnswer = question.answers[question.correctAnswer]
        
        Task {
            do {
                let response = try await QuizService.getQuizExplanation(
                    question: questionText,
                    userAnswer: userAnswer,
                    correctAnswer: correctAnswer,
                    videoUUID: videoUUID
                )
                await MainActor.run {
                    self.explanation = response.explanation
                    self.showingExplanation = true
                }
            } catch {
                await MainActor.run {
                    self.explanation = "Failed to load explanation: \(error.localizedDescription)"
                    self.showingExplanation = true
                }
            }
        }
    }
    
    func restartQuiz() {
        currentIndex = 0
        selectedAnswers = Array(repeating: nil, count: questions.count)
        aiExplanations.removeAll()
        revealedAnswers.removeAll()
        quizUUID = nil
        state = .loading
        loadQuiz()
    }

    //MARK: - Private Methods
}

// MARK: - Helper Types for QuizViewModel
// (Enums, structs, etc. used by QuizViewModel)
