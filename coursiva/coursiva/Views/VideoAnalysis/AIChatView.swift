//
//  AIChatView.swift
//  coursiva
//
//  Created by Z1 on 23.06.2025.
//

import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    let timestamp: Date = Date()
}

struct AIChatView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: AIChatViewModel
    
    init(videoUUID: String) {
        self._viewModel = StateObject(wrappedValue: AIChatViewModel(videoUUID: videoUUID))
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(localized: "AI Tutor")
                        .font(.custom("Futura-Bold", size: 22))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                ZStack {
                    if viewModel.messages.isEmpty && !viewModel.isLoading {
                        Text(localized: "Ask me anything about this video")
                            .font(.custom("Futura-Bold", size: 20))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .foregroundStyle(Color.appText)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }
                                if viewModel.isLoading {
                                    HStack {
                                        TypingIndicator()
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .id("loading")
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .onChange(of: viewModel.messages.count) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if let lastMessage = viewModel.messages.last {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: viewModel.isLoading) {
                            if viewModel.isLoading {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo("loading", anchor: .bottom)
                                }
                            }
                        }
                    }
                }

                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(localized: errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }

                Divider()
                    .background(Color.gray.opacity(0.3))

                // Input area
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $viewModel.inputText)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color.appSurface)
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .disabled(viewModel.isLoading)
                        .onSubmit {
                            viewModel.sendMessage()
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }

                    Button {
                        viewModel.sendMessage()
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(viewModel.isLoading ? .gray : Color.appSecondary)
                    }
                    .disabled(viewModel.isLoading || viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(Color.background)
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .background(Color.background)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    @State private var height: CGFloat = 1
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(localized: message.text)
                        .textSelection(.enabled)
                        .padding(12)
                        .font(.callout)
                        .foregroundColor(.white)
                        .background(
                            LinearGradient.defaulGradient
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        )
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .trailing)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    // AI response: Markdown, no bubble, full width
                    let processedText = message.text.replacingOccurrences(of: "\\n", with: "\n")
                    MarkdownMathView(markdownText: processedText, dynamicHeight: $height, backgroundColor: Color.appBackground)
                        .frame(height: height)
                }
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationOffset == CGFloat(index) ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animationOffset
                    )
            }
        }
        .padding(12)
        .background(Color.appSurface)
        .cornerRadius(16)
        .onAppear {
            animationOffset = 2
        }
    }
}

#Preview {
    AIChatView(videoUUID: "456e7890-e89b-12d3-a456-426614174111")
}

