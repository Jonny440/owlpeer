//
//  QuizView.swift
//  coursiva
//
//  Created by Z1 on 23.06.2025.
//

import SwiftUI

struct QuizView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: QuizViewModel
    
    init(videoUUID: String) {
        self._viewModel = StateObject(wrappedValue: QuizViewModel(videoUUID: videoUUID))
    }

    var body: some View {
        VStack(spacing: 0) {
            QuizHeaderView(dismiss: dismiss)
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            QuizMainContentView(viewModel: viewModel)
        }
        .background(Color.background)
        .onAppear {
            viewModel.loadQuiz()
        }
        .sheet(isPresented: $viewModel.showingExplanation) {
            QuizExplanationSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Header Components
struct QuizHeaderView: View {
    let dismiss: DismissAction
    
    var body: some View {
        HStack {
            Text(localized: "Quiz")
                .font(.custom("Futura-Bold", size: 22))
                .fontWeight(.bold)
                .foregroundColor(.white)
            Spacer()
            CloseButton(action: dismiss.callAsFunction)
        }
        .padding()
    }
}

struct CloseButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(10)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
        }
    }
}

// MARK: - Main Content Router
struct QuizMainContentView: View {
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                LoadingView(message:  "Loading quiz...".localized)
            case .error(let error):
                ErrorView(error: error, retryAction: viewModel.loadQuiz)
            case .loaded:
                ActiveQuizView(viewModel: viewModel)
            case .alreadyCompleted(let quiz):
                CompletedQuizView(quiz: quiz, viewModel: viewModel)
            case .noQuiz:
                EmptyStateView(
                    title: "No Quiz Available",
                    message: "Generate quiz to enhance your understanding of this video content.",
                    buttonTitle: "Generate Quiz",
                    action: { viewModel.generateQuiz() }
                )
            }
        }
    }
}

// MARK: - Reusable Components
struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text(localized: message)
                .foregroundColor(.gray)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            Text(localized: "Error loading quiz")
                .font(.headline)
                .foregroundColor(.white)
            Text(localized: error.localizedDescription)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            PrimaryButton(title: "Retry", action: retryAction)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NoQuizView: View {
    let generateAction: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text(localized: "No quiz found for this video.")
                .foregroundColor(.gray)
            
            PrimaryButton(title:  "Generate quiz".localized, action: generateAction)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Button Components
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    let isLoading: Bool
    let isDisabled: Bool
    
    init(title: String, action: @escaping () -> Void, isLoading: Bool = false, isDisabled: Bool = false) {
        self.title = title
        self.action = action
        self.isLoading = isLoading
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                }
                Text(localized: title)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(LinearGradient.defaulGradient)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isDisabled || isLoading)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    let isDisabled: Bool
    
    init(title: String, action: @escaping () -> Void, isDisabled: Bool = false) {
        self.title = title
        self.action = action
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        Button(action: action) {
            Text(localized: title)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.appSurface)
                .foregroundColor(.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white, lineWidth: 0.5)
                )
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

// MARK: - Active Quiz Content
struct ActiveQuizView: View {
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                QuizProgressSection(viewModel: viewModel)
                QuizQuestionSection(viewModel: viewModel)
                QuizNavigationSection(viewModel: viewModel)
                QuizExplanationSection(viewModel: viewModel)
            }
            .padding(.vertical)
        }
    }
}

struct QuizProgressSection: View {
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProgressView(value: viewModel.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color.appPrimary))
                .padding(.horizontal)
            
            if viewModel.hasPartialProgress {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                    Text(localized: "Resuming previous progress")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)
            }
            
            Text(String.localizedStringWithFormat(NSLocalizedString("Question %lld of %lld", comment: ""), viewModel.currentIndex + 1, viewModel.questions.count))
            .font(.caption)
            .foregroundColor(.gray)
            .padding(.horizontal)
        }
    }
}

struct QuizQuestionSection: View {
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
        if let question = viewModel.currentQuestion {
            VStack(alignment: .leading, spacing: 16) {
                Text(localized: question.question)
                    .font(.headline)
                    .foregroundColor(Color.text)
                    .padding(.horizontal)
                
                ForEach(question.answers.indices, id: \.self) { index in
                    QuizAnswerOption(
                        text: question.answers[index],
                        label: QuizConstants.optionLabels[index],
                        isSelected: viewModel.selectedAnswers[viewModel.currentIndex] == index,
                        action: { viewModel.selectAnswer(index) }
                    )
                }
            }
        }
    }
}

struct QuizNavigationSection: View {
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            SecondaryButton(
                title: "Previous",
                action: viewModel.previousQuestion,
                isDisabled: viewModel.currentIndex == 0
            )
            
            if viewModel.canSubmit {
                PrimaryButton(
                    title: viewModel.isSubmitting ?  "Submitting...".localized :  "Submit Quiz".localized,
                    action: viewModel.submitQuiz,
                    isLoading: viewModel.isSubmitting,
                    isDisabled: viewModel.isSubmitting
                )
            } else {
                SecondaryButton(
                    title: "Next",
                    action: viewModel.nextQuestion,
                    isDisabled: !viewModel.canProceed
                )
            }
        }
        .padding(.horizontal)
    }
}

struct QuizExplanationSection: View {
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
        if let aiExplanation = viewModel.getAIExplanation(for: viewModel.currentIndex) {
            AIExplanationView(explanation: aiExplanation)
        }
    }
}

// MARK: - Answer Option Components
struct QuizAnswerOption: View {
    let text: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            AnswerOptionContent(text: text, label: label, isSelected: isSelected)
        }
        .padding(.horizontal)
    }
}

struct CompletedQuizAnswerOption: View {
    let text: String
    let label: String
    let isSelected: Bool
    let isCorrect: Bool
    
    var body: some View {
        Button(action: {}) {
            HStack(alignment: .top) {
                AnswerOptionContent(text: text, label: label, isSelected: isSelected)
                
                Spacer()
                
                AnswerIndicator(isSelected: isSelected, isCorrect: isCorrect)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(answerBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .disabled(true)
    }
    
    private var answerBackground: Color {
        if isSelected {
            return isCorrect ? Color.green.opacity(0.3) : Color.red.opacity(0.3)
        } else if isCorrect {
            return Color.green.opacity(0.1)
        } else {
            return Color.appSurface
        }
    }
}

struct AnswerOptionContent: View {
    let text: String
    let label: String
    let isSelected: Bool
    
    var body: some View {
        HStack(alignment: .top) {
            Text(localized: "\(label).")
                .bold()
                .foregroundColor(Color.text)
            Text(localized: text)
                .foregroundColor(Color.text)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.appPrimary.opacity(0.3) : Color.appSurface)
        .cornerRadius(12)
    }
}

struct AnswerIndicator: View {
    let isSelected: Bool
    let isCorrect: Bool
    
    var body: some View {
        Group {
            if isSelected {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isCorrect ? .green : .red)
            } else if isCorrect {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
}

// MARK: - Completed Quiz View
struct CompletedQuizView: View {
    let quiz: Quiz
    @ObservedObject var viewModel: QuizViewModel
    @State private var isScoreExpanded = true
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                CompletedQuizHeader(quiz: quiz, isExpanded: $isScoreExpanded)
                
                Text(String.localizedStringWithFormat(NSLocalizedString("Question %lld of %lld", comment: ""), viewModel.currentIndex + 1, viewModel.questions.count))
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                CompletedQuizQuestionSection(viewModel: viewModel)
                CompletedQuizNavigationSection(viewModel: viewModel)
                CompletedQuizExplanationSection(viewModel: viewModel)
            }
            .padding(.vertical)
        }
    }
}

struct CompletedQuizHeader: View {
    let quiz: Quiz
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.custom("Futura-Bold", size: 22))
                            Text(localized: "Quiz Completed!")
                                .font(.custom("Futura-Bold", size: 22))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        if let scorePercentage = quiz.scorePercentage {
                            Text(localized: "\(Int(scorePercentage))%")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up")
                        .foregroundColor(.gray)
                        .font(.title3)
                        .rotationEffect(.degrees(isExpanded ? 0 : 180))
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.appSurface, Color.appSurface.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                CompletedQuizStats(quiz: quiz)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal)
    }
}

struct CompletedQuizStats: View {
    let quiz: Quiz
    
    var body: some View {
        if let correctAnswers = quiz.correctAnswersCount,
           let totalQuestions = quiz.questionsCount {
            VStack(spacing: 12) {
                HStack {
                    StatView(title:  "Correct Answers".localized, value: "\(correctAnswers)", color: .green)
                    Spacer()
                    StatView(title:  "Total Questions".localized, value: "\(totalQuestions)", color: .white)
                }
                .padding()
                .background(Color.appSurface.opacity(0.5))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

struct StatView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(localized: title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(localized: value)
                .font(.custom("Futura-Bold", size: 22))
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

struct CompletedQuizQuestionSection: View {
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
        if let question = viewModel.currentQuestion {
            VStack(alignment: .leading, spacing: 16) {
                Text(localized: question.question)
                    .font(.headline)
                    .foregroundColor(Color.text)
                    .padding(.horizontal)
                
                ForEach(question.answers.indices, id: \.self) { index in
                    CompletedQuizAnswerOption(
                        text: question.answers[index],
                        label: QuizConstants.optionLabels[index],
                        isSelected: viewModel.selectedAnswers[viewModel.currentIndex] == index,
                        isCorrect: index == question.correctAnswer
                    )
                }
            }
        }
    }
}

struct CompletedQuizNavigationSection: View {
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            SecondaryButton(
                title: "Previous",
                action: viewModel.previousQuestion,
                isDisabled: viewModel.currentIndex == 0
            )
            
            SecondaryButton(
                title: "Next",
                action: viewModel.nextQuestion,
                isDisabled: viewModel.currentIndex == viewModel.questions.count - 1
            )
        }
        .padding(.horizontal)
    }
}

struct CompletedQuizExplanationSection: View {
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
        if let aiExplanation = viewModel.getAIExplanation(for: viewModel.currentIndex) {
            AIExplanationView(explanation: aiExplanation)
        } else {
            VStack {
                PrimaryButton(
                    title: viewModel.isLoadingAIExplanation ?  "Loading...".localized :  "Get AI Explanation".localized,
                    action: viewModel.requestAIExplanation,
                    isLoading: viewModel.isLoadingAIExplanation,
                    isDisabled: viewModel.isLoadingAIExplanation
                )
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Supporting Views
struct AIExplanationView: View {
    let explanation: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text(localized: "AI Explanation")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.yellow)
            }
            
            Text(localized: explanation)
                .font(.body)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
        }
        .padding(.horizontal)
    }
}

struct QuizExplanationSheet: View {
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let attributedExplanation = try? AttributedString(markdown: viewModel.explanation) {
                        Text(attributedExplanation)
                            .foregroundColor(.white)
                    } else {
                        Text(localized: viewModel.explanation)
                            .foregroundColor(.white)
                    }
                }
                .padding()
            }
            .background(Color.background)
            .navigationTitle("Quiz Explanation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.showingExplanation = false
                    }
                }
            }
        }
    }
}

// MARK: - Constants
enum QuizConstants {
    static let optionLabels = ["A", "B", "C", "D"]
}

// MARK: - Legacy Views (kept for compatibility)
struct QuizResultView: View {
    let result: QuizSubmissionResponse
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text(localized: "Quiz Completed!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    Text(localized: "\(Int(result.score * 100))%")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.green)
                    
                    Text(localized: "\(result.correctAnswers) out of \(result.totalQuestions) correct")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.appSurface)
                .cornerRadius(12)
            }
            
            if !result.feedback.isEmpty {
                Text(localized: result.feedback)
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            
            VStack(spacing: 12) {
                PrimaryButton(title:  "Review Answers".localized, action: {})
                
                Button("Restart Quiz") {
                    viewModel.restartQuiz()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
