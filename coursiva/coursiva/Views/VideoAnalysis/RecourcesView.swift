//
//  RecourcesView.swift
//  Owlpeer
//
//  Created by Z1 on 29.08.2025.
//

import SwiftUI

struct RecourcesView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: RecourcesViewModel
    var id: UUID
    
    init(id: UUID) {
        _viewModel = StateObject(wrappedValue: RecourcesViewModel(id: id))
        self.id = id
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(localized: "Resources")
                    .font(.custom("Futura-Bold", size: 24))
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
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Content
            contentView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.background.ignoresSafeArea())
        .onAppear {
            Task {
                await viewModel.fetch()
            }
        }
    }
    
    @ViewBuilder
    private func contentView() -> some View {
        switch viewModel.state {
        case .loading:
            VStack(spacing: 20) {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text(localized: "Loading resources...")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .noRecources:
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundColor(.blue.opacity(0.8))
                
                Text(localized: "No Resources Available")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(localized: "Generate learning resources to enhance your understanding of this video content.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Button(action: {
                    viewModel.generateRecources()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text(localized: "Generate Resources")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Spacer()
            }
            .padding(.horizontal, 20)

        case .loaded(let recources):
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let title = recources.title {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(localized: "Title")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(localized: title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    
                    if let markdown = recources.recourcesMarkdown {
                        MarkdownView(markdown: markdown)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    
                    if let updatedAt = recources.updatedAt {
                        HStack {
                            Image(systemName: "clock")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            Text(localized: "Last updated: \(updatedAt)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

        case .error(let error):
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 60))
                    .foregroundColor(.red.opacity(0.8))
                
                Text(localized: "Error Loading Resources")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(localized: error)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Button("Retry") {
                    Task {
                        await viewModel.fetch()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Custom Markdown View
struct MarkdownView: View {
    let markdown: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(parseMarkdown(markdown), id: \.id) { element in
                switch element.type {
                case .header:
                    Text(localized: element.text)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    
                case .listItem:
                    HStack(alignment: .top, spacing: 12) {
                        Text(localized: "\(element.number).")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.blue.opacity(0.8))
                            .frame(width: 25, alignment: .trailing)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            if let link = element.link {
                                Button(action: {
                                    openURL(link)
                                }) {
                                    Text(localized: element.text)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                        .underline()
                                        .multilineTextAlignment(.leading)
                                }
                            } else {
                                Text(localized: element.text)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                    
                case .text:
                    Text(localized: element.text)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .padding(.bottom, 24)
                }
            }
        }
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func parseMarkdown(_ markdown: String) -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        let lines = markdown.components(separatedBy: .newlines)
        
        var currentNumber = 1
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.isEmpty { continue }
            
            // Check for headers (###)
            if trimmedLine.hasPrefix("###") {
                let headerText = trimmedLine.replacingOccurrences(of: "###", with: "").trimmingCharacters(in: .whitespaces)
                elements.append(MarkdownElement(
                    id: UUID(),
                    type: .header,
                    text: headerText,
                    number: 0,
                    link: nil,
                    description: nil
                ))
                continue
            }
            
            // Check for numbered list items (1. [text](url))
            if let regex = try? NSRegularExpression(pattern: #"^(\d+)\.\s*\[([^\]]+)\]\(([^)]+)\)"#) {
                let range = NSRange(trimmedLine.startIndex..<trimmedLine.endIndex, in: trimmedLine)
                if let match = regex.firstMatch(in: trimmedLine, range: range) {
                    let numberRange = Range(match.range(at: 1), in: trimmedLine)!
                    let textRange = Range(match.range(at: 2), in: trimmedLine)!
                    let urlRange = Range(match.range(at: 3), in: trimmedLine)!
                    
                    let number = String(trimmedLine[numberRange])
                    let text = String(trimmedLine[textRange])
                    let url = String(trimmedLine[urlRange])
                    
                    // Look for description on next line (starts with →)
                    var description: String? = nil
                    if let nextLineIndex = lines.firstIndex(of: line)?.advanced(by: 1),
                       nextLineIndex < lines.count {
                        let nextLine = lines[nextLineIndex].trimmingCharacters(in: .whitespaces)
                        if nextLine.hasPrefix("→") {
                            description = nextLine.replacingOccurrences(of: "→", with: "").trimmingCharacters(in: .whitespaces)
                        }
                    }
                    
                    elements.append(MarkdownElement(
                        id: UUID(),
                        type: .listItem,
                        text: text,
                        number: Int(number) ?? currentNumber,
                        link: url,
                        description: description
                    ))
                    
                    currentNumber += 1
                    continue
                }
            }
            
            // Check for regular numbered list items (1. text)
            if let regex = try? NSRegularExpression(pattern: #"^(\d+)\.\s*(.+)"#) {
                let range = NSRange(trimmedLine.startIndex..<trimmedLine.endIndex, in: trimmedLine)
                if let match = regex.firstMatch(in: trimmedLine, range: range) {
                    let numberRange = Range(match.range(at: 1), in: trimmedLine)!
                    let textRange = Range(match.range(at: 2), in: trimmedLine)!
                    
                    let number = String(trimmedLine[numberRange])
                    let text = String(trimmedLine[textRange])
                    
                    elements.append(MarkdownElement(
                        id: UUID(),
                        type: .listItem,
                        text: text,
                        number: Int(number) ?? currentNumber,
                        link: nil,
                        description: nil
                    ))
                    
                    currentNumber += 1
                    continue
                }
            }
            
            // Regular text
            elements.append(MarkdownElement(
                id: UUID(),
                type: .text,
                text: trimmedLine,
                number: 0,
                link: nil,
                description: nil
            ))
        }
        
        return elements
    }
}

// MARK: - Markdown Element Model
struct MarkdownElement {
    let id: UUID
    let type: MarkdownElementType
    let text: String
    let number: Int
    let link: String?
    let description: String?
}

enum MarkdownElementType {
    case header
    case listItem
    case text
}

