//
//  test.swift
//  coursiva
//
//  Created by Z1 on 17.07.2025.
//
import SwiftUI
import YouTubeiOSPlayerHelper

struct YouTubePlayerRepresentable: UIViewRepresentable {
    let videoID: String
    @Binding var seekToTime: Double?

    class Coordinator: NSObject {
        var parent: YouTubePlayerRepresentable
        var playerView: YTPlayerView?
        var observer: NSObjectProtocol?
        
        init(parent: YouTubePlayerRepresentable) {
            self.parent = parent
        }
        
        deinit {
            if let observer = observer {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> YTPlayerView {
        let playerView = YTPlayerView()
        context.coordinator.playerView = playerView
        let playerVars: [String: Any] = [
            "playsinline": 1,
            "rel": 0,
            "modestbranding": 1,
            "controls": 1,
            "iv_load_policy": 3,
            "showinfo": 0
        ]
        playerView.load(withVideoId: videoID, playerVars: playerVars)
        // Listen for termination notification
        context.coordinator.observer = NotificationCenter.default.addObserver(forName: Notification.Name("TerminateYouTubePlayer"), object: nil, queue: .main) { [weak playerView] _ in
            playerView?.stopVideo()
            // Optionally, remove from superview if needed
            playerView?.removeFromSuperview()
        }
        return playerView
    }

    func updateUIView(_ uiView: YTPlayerView, context: Context) {
        if let time = seekToTime {
            uiView.seek(toSeconds: Float(time), allowSeekAhead: true)
            DispatchQueue.main.async {
                self.seekToTime = nil
            }
        }
    }
}

