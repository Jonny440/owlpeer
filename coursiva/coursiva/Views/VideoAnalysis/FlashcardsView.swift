//
//  FlashcardsView.swift
//  coursiva
//
//  Created by Z1 on 23.06.2025.
//

import SwiftUI

struct FlashcardsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: FlashcardsViewModel
    @State private var flipResetTrigger: Int = 0
    @State private var isFlipping: Bool = false
    let id: UUID
    
    init(id: UUID) {
        self.id = id
        _viewModel = StateObject(wrappedValue: FlashcardsViewModel(id: id))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                HStack {
                    Text(localized: "Flashcards")
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
                contentView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            }
        }
        .background(Color.background)
        .onAppear {
            viewModel.fetch()
        }
    }

    @ViewBuilder
    private func contentView() -> some View {
        switch viewModel.state {
        case .loading:
            VStack {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                Text(localized: "Loading flashcards...")
                    .foregroundColor(.gray)
                    .padding(.top)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .error(let error):
            Text(localized: "Error: \(error.localizedDescription)")
                .foregroundColor(.red)
                .padding()
                .frame(minHeight: 120, maxHeight: 300)

        case .noFlashcards:
            EmptyStateView(
                title: "No Flashcards Available",
                message: "Generate flashcards to enhance your understanding of this video content.",
                buttonTitle: "Generate Flashcards",
                action: { viewModel.generateFlashcards() }
            )

        case .loaded(let flashcards):
            if viewModel.isGenerating {
                VStack(spacing: 16) {
                    ProgressView("Generating flashcards...")
                        .frame(height: 200)
                }
            } else if flashcards.isEmpty {
                EmptyStateView(
                    title: "No Resources Available",
                    message: "Generate learning resources to enhance your understanding of this video content.",
                    buttonTitle: "Generate Resources",
                    action: { viewModel.generateFlashcards() }
                )
            } else {
                VStack(spacing: 16) {
                    Text(String.localizedStringWithFormat(NSLocalizedString("Card %lld of %lld", comment: ""), viewModel.currentCardIndex + 1, flashcards.count ))
                        .font(.caption)
                        .foregroundColor(.gray)

                    FlashcardView(
                        isFlipping: $isFlipping,
                        frontText: flashcards[viewModel.currentCardIndex].question,
                        backText: flashcards[viewModel.currentCardIndex].answer,
                        resetTrigger: flipResetTrigger
                    )

                    HStack(spacing: 16) {
                        Button(action: {
                            if !isFlipping {
                                if viewModel.currentCardIndex == 0 {
                                    viewModel.currentCardIndex = flashcards.count - 1
                                } else {
                                    viewModel.previousCard()
                                }
                                flipResetTrigger += 1
                            }
                        }) {
                            Text(localized: "Previous")
                                .bold()
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
                        .disabled(isFlipping)
                        
                        Spacer()
                        
                        Button(action: {
                            if !isFlipping {
                                if viewModel.currentCardIndex == flashcards.count - 1 {
                                    viewModel.currentCardIndex = 0
                                } else {
                                    viewModel.nextCard()
                                }
                                flipResetTrigger += 1
                            }
                        }) {
                            Text(localized: "Next")
                                .bold()
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
                        .disabled(isFlipping)
                    }
                    Spacer()
                }
            }
        }
    }
}

struct FlashcardView: View {
    @Binding var isFlipping: Bool
    @State private var rotation: Double = 0
    @State private var showBackOnTop: Bool = false
    let frontText: String
    let backText: String
    let resetTrigger: Int

    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width
            let cardHeight = cardWidth * 0.66

            ZStack {
                Text(localized: frontText)
                    .font(.callout)
                    .fontWeight(.medium)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(width: cardWidth, height: cardHeight)
                    .background(Color.clear)
                    .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
                    .zIndex(showBackOnTop ? 0 : 2)

                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appSurface)
                    .frame(width: cardWidth, height: cardHeight)
                    .shadow(radius: 8)
                    .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
                    .zIndex(1)

                Text(localized: backText)
                    .font(.callout)
                    .fontWeight(.medium)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(width: cardWidth, height: cardHeight)
                    .background(Color.clear)
                    .rotation3DEffect(.degrees(rotation - 180), axis: (x: 0, y: 1, z: 0))
                    .zIndex(showBackOnTop ? 2 : 0)
            }
            .frame(width: cardWidth, height: cardHeight)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .aspectRatio(3/2, contentMode: .fit)
        .onTapGesture {
            flipCard()
        }
        .onChange(of: resetTrigger) {
            resetFlip()
        }
    }

    private func flipCard() {
        guard !isFlipping else { return }
        isFlipping = true
        let flippingToBack = rotation < 90
        withAnimation(.linear(duration: 0.4)) {
            rotation = flippingToBack ? 180 : 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showBackOnTop = flippingToBack
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isFlipping = false
        }
    }

    private func resetFlip() {
        isFlipping = false
        rotation = 0
        showBackOnTop = false
    }
}
