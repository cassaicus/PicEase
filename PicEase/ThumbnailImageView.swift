import SwiftUI

struct ThumbnailImageView: View {
    let url: URL
    @StateObject private var loader = ThumbnailLoader()

    var body: some View {
        Group {
            if let image = loader.image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // 読み込み中はプレースホルダー
                Color.gray.opacity(0.3)
            }
        }
        .onAppear {
            loader.load(from: url)
        }
    }
}
