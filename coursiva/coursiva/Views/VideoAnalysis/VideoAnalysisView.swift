//
//  VideoAnalysisView.swift
//  coursiva
//
//  Created by Z1 on 23.06.2025.
//

import SwiftUI


struct VideoAnalysisView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: VideoAnalysisViewModel
    @State private var height: CGFloat = 1
    @State private var isTranscriptCollapsed: Bool = true
    @State private var showingAIChat = false
    let id: UUID

    init(id: UUID) {
        self.id = id
        _viewModel = StateObject(wrappedValue: VideoAnalysisViewModel(id: id))
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(localized: "Video Summary")
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
                .background(Color.background)
                Divider()
                    .background(Color.gray.opacity(0.3))
                ScrollView {
                    VStack(spacing: 16) {
                        switch viewModel.state {
                        case .loading:
                            VStack {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text(localized: "Loading video analysis...")
                                    .foregroundColor(.gray)
                                    .padding(.top)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.appBackground)
                        case .error(let error):
                            ZStack {
                                Color.appBackground
                                    .ignoresSafeArea()
                                VStack {
                                    Spacer()
                                    Text(localized: "Error: \(error.localizedDescription)")
                                        .foregroundColor(.red)
                                        .font(.title3)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        case .loaded(let video):
                            if let videoID = extractYouTubeID(from: video.url) {
                                YouTubePlayerRepresentable(videoID: videoID, seekToTime: $viewModel.seekToTime)
                                    .aspectRatio(16/9, contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                Rectangle()
                                    .fill(Color.blue)
                                    .aspectRatio(16/9, contentMode: .fit)
                            }
                            // Transcript Section
                            if let transcript = video.timecodeTranscript, !transcript.isEmpty {
                                VStack(alignment: .leading, spacing: 0) {
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isTranscriptCollapsed.toggle()
                                        }
                                    }) {
                                        HStack {
                                            Text(localized: "Transcript")
                                                .font(.custom("Futura-Bold", size: 19))
                                                .minimumScaleFactor(0.5)
                                                .foregroundColor(Color.text)
                                            Spacer()
                                            Image(systemName: isTranscriptCollapsed ? "chevron.down" : "chevron.up")
                                                .foregroundColor(Color.text)
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 12)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if !isTranscriptCollapsed {
                                        ScrollView {
                                            LazyVStack(alignment: .leading, spacing: 12) {
                                                ForEach(transcript.indices, id: \.self) { idx in
                                                    let line = transcript[idx]
                                                    
                                                    TranscriptSegmentViewClean(
                                                        line: line,
                                                        onTap: {
                                                            if let seconds = parseTimecode(line.start) {
                                                                viewModel.seekToTime = seconds
                                                            }
                                                        }
                                                    )
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                        }
                                        .frame(minHeight: 120, maxHeight: 320)
                                    }
                                }
                                .background(Color.appSurface)
                                .cornerRadius(10)
                                .animation(.easeInOut(duration: 0.2), value: isTranscriptCollapsed)
                            }
                            
                            // Use MarkdownUI to render summary
                            let processedSummary = video.summary.replacingOccurrences(of: "\\n", with: "\n")
                            MarkdownMathView(markdownText: processedSummary, dynamicHeight: $height, backgroundColor: Color.appBackground)
                                .frame(height: height)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
                .background(Color.appBackground)
            }
            .sheet(isPresented: $showingAIChat) {
                AIChatView(videoUUID: id.uuidString.lowercased())
            }
            .onAppear {
                viewModel.fetch()
            }
            .onDisappear {
                // Terminate the YouTube player when the view disappears
                NotificationCenter.default.post(name: Notification.Name("TerminateYouTubePlayer"), object: nil)
            }
        }
    }

    
    func extractYouTubeID(from urlString: String) -> String? {
        guard let components = URLComponents(string: urlString) else {
            return nil
        }

        if components.host?.contains("youtube.com") == true,
           let queryItems = components.queryItems,
           let videoID = queryItems.first(where: { $0.name == "v" })?.value {
            return videoID
        }

        if components.host?.contains("youtu.be") == true,
           let path = components.path.split(separator: "/").first {
            return String(path)
        }

        return nil
    }
    
    func parseTimecode(_ timecode: String) -> Double? {
        let parts = timecode.split(separator: ":").compactMap { Double($0) }
        guard parts.count == 2 else { return nil }
        return parts[0] * 60 + parts[1]
    }
}

struct TranscriptSegmentView: View {
    var line: TranscriptSegment
    var isActive: Bool = false
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(localized: line.start)
                .font(.footnote)
                .foregroundColor(isActive ? .white : .blue)
                .frame(width: 56, alignment: .center)
                .alignmentGuide(.firstTextBaseline) { d in d[.bottom] }
            Text(localized: line.text.replacingOccurrences(of: "\n", with: ""))
                .font(.callout)
                .foregroundColor(isActive ? .white : Color.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? Color.appPrimary : Color.surface)
                .shadow(color: isActive ? Color.appPrimary.opacity(0.2) : .clear, radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color.appPrimary : Color.clear, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.15), value: isActive)
    }
}

struct TranscriptSegmentViewClean: View {
    var line: TranscriptSegment
    var onTap: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Timestamp
            Text(localized: line.start)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .frame(width: 50)
                .multilineTextAlignment(.center)
            
            // Text content
            Text(localized: line.text.replacingOccurrences(of: "\n", with: " "))
                .font(.callout)
                .foregroundColor(Color.text)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.surface)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}
