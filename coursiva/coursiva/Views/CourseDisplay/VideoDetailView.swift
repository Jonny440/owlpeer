//
//  CourseDetailView.swift
//  coursiva
//
//  Created by Z1 on 23.06.2025.
//

import SwiftUI
import Kingfisher

struct VideoDetailView: View {
    let id: UUID
    let title: String
    let thumbnail: URL?

    enum ActiveSheet: Identifiable {
        case analysis, flashcards, quiz, chat, mindmap, recources
        var id: Int { hashValue }
    }

    @State private var activeSheet: ActiveSheet?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SafeKFImage(url: thumbnail)

                    HStack(spacing: 16) {
                        Button {
                            activeSheet = .analysis
                        } label: {
                            videoActionItem(title: "Video Summary", icon: "file-video")
                        }
                        
                        Button {
                            activeSheet = .flashcards
                        } label: {
                            videoActionItem(title: "Flashcards", icon: "layers")
                        }
                    }
                    
                    HStack(spacing: 16) {
                        Button {
                            activeSheet = .quiz
                        } label: {
                            videoActionItem(title: "Quiz", icon: "notebook-pen")
                        }
                        
                        Button {
                            activeSheet = .chat
                        } label: {
                            videoActionItem(title: "AI Tutor", icon: "brain-cog")
                        }
                    }
                    
                    HStack(spacing: 16) {
                        Button {
                            activeSheet = .recources
                        } label: {
                            videoActionItem(title: "Resources", icon: "code-xml2")
                        }
                    }
                }
                .padding()
            }
            .background(Color.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenCover(item: $activeSheet) { item in
            switch item {
            case .analysis:
                VideoAnalysisView(id: id)
            case .flashcards:
                FlashcardsView(id: id)
            case .quiz:
                QuizView(videoUUID: id.uuidString)
            case .chat:
                AIChatView(videoUUID: id.uuidString)
            case .mindmap:
                MindMapViewFull(id: id)
            case .recources:
                RecourcesView(id: id)
            }
        }
    }

    private func videoActionItem(title: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    LinearGradient.defaulGradient
                )
                .cornerRadius(12)

            Text(localized: title)
                .font(.subheadline)
                .foregroundColor(Color.text)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.appSurface)
        .cornerRadius(16)
    }
}
