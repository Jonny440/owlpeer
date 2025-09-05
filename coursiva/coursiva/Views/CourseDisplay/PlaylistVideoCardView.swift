import SwiftUI
import Kingfisher

struct PlaylistVideoCardView: View {
    let id: UUID
    let title: String
    let thumbnailURL: URL?
    @State private var fallback = false

    var body: some View {
        NavigationLink(destination: VideoDetailView(id: id, title: title, thumbnail: thumbnailURL)) {
            VStack(alignment: .leading, spacing: 8) {
                SafeKFImage(url: thumbnailURL)

                HStack {
                    Text(localized: title)
                        .foregroundColor(Color.text)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
            .padding(7)
            .frame(width: UIScreen.main.bounds.width / 2.2)
            .background(Color("surfaceColor"))
            .cornerRadius(16)
        }
    }
} 
