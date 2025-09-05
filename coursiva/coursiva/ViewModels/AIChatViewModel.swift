//
//  AIChatViewModel.swift
//  coursiva
//
//  Created by Z1 on 07.07.2025.
//

import Foundation
import SwiftUI


@MainActor
class AIChatViewModel: ObservableObject {
    
    //MARK: - Public Properties
    
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    //MARK: - Private Properties
    
    private let videoUUID: String
    
    //MARK: - Init
    
    init(videoUUID: String) {
        self.videoUUID = videoUUID
    }
    
    //MARK: - Public Methods
    
    func sendMessage() {
        let trimmedMessage = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty, !isLoading else { return }
        
        let userMessage = ChatMessage(text: trimmedMessage, isFromUser: true)
        messages.append(userMessage)
        inputText = ""
        
        Task {
            await sendMessageToAI(trimmedMessage)
        }
    }
    
    func clearChat() {
        messages.removeAll()
        errorMessage = nil
    }
    
    //MARK: - Private Methods
    
    private func sendMessageToAI(_ question: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let raw = try await AIChatService.sendMessage(question, videoUUID: videoUUID) as String
            let message = Self.parseAIResponse(raw)
            let aiMessage = ChatMessage(text: message, isFromUser: false)
            messages.append(aiMessage)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private static func parseAIResponse(_ raw: String) -> String {
        raw.components(separatedBy: .newlines)
            .filter { $0.hasPrefix("data: ") && !$0.contains("[DONE]") }
            .map { $0.replacingOccurrences(of: "data: ", with: "") }
            .joined()
    }
    
} 

