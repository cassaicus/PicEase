
import SwiftUI
import ImageIO

struct ThumbnailScrollView: View {
    let imageURLs: [URL]
    @Binding var currentIndex: Int
    @Binding var isThumbnailVisible: Bool
    @State private var thumbnails: [URL: NSImage] = [:]
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal, showsIndicators: true) {
                LazyHStack(spacing: 8) {
                    ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                        let isSelected = index == currentIndex
                        ZStack {
                            if let image = thumbnails[url] {
                                Image(nsImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else {
                                Color.gray
                            }
                        }
                        .frame(width: 80, height: 80)
                        .clipped()
                        .border(isSelected ? Color.blue : Color.clear, width: 2)
                        .id(index) // ← ScrollViewReader で使うための ID
                        .onTapGesture {
                            currentIndex = index
                            NotificationCenter.default.post(name: .thumbnailSelected, object: index)
                        }
                        .onAppear {
                            if thumbnails[url] == nil {
                                loadThumbnailAsync(for: url)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .onChange(of: currentIndex) { oldValue, newIndex in
                    withAnimation {
                        scrollProxy.scrollTo(newIndex, anchor: .center)
                    }
            }
            .task(id: isThumbnailVisible) {
                if isThumbnailVisible {
                        scrollProxy.scrollTo(currentIndex, anchor: .center)
                }
            }
        }
    }
    
    // MARK: - Retina対応サムネイル生成（2xサイズで読み込み）
    func loadThumbnailAsync(for url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            let targetSize = CGSize(width: 80, height: 80)
            let scaleFactor = NSScreen.main?.backingScaleFactor ?? 2.0
            let pixelSize = CGSize(width: targetSize.width * scaleFactor, height: targetSize.height * scaleFactor)
            
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return }
            
            let options: [NSString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: max(pixelSize.width, pixelSize.height),
                kCGImageSourceCreateThumbnailWithTransform: true
            ]
            
            if let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
                let image = NSImage(cgImage: cgImage, size: targetSize)
                DispatchQueue.main.async {
                    thumbnails[url] = image
                }
            }
        }
    }
}
