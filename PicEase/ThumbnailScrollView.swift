import SwiftUI

struct ThumbnailScrollView: View {
    let imageURLs: [URL]
    @Binding var currentIndex: Int

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: true) {
                HStack {
                    ForEach(Array(imageURLs.enumerated()), id: \.offset) { pair in
                        let index = pair.offset
                        let imageUrl = pair.element

                        let image = ImageCache.shared.thumbnail(for: imageUrl) ?? NSImage()

                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipped()
                            .border(currentIndex == index ? Color.white : Color.clear, width: 2)
                            .onTapGesture {
                                currentIndex = index
                                NotificationCenter.default.post(name: .thumbnailSelected, object: index)
                            }
                            .id(index) // scrollTo用
                    }
                }
                .padding(.horizontal)
            }
            .onChange(of: currentIndex) { newIndex in
                withAnimation {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    proxy.scrollTo(currentIndex, anchor: .center)
                }
            }
        }
    }
}



class ImageCache {
    static let shared = ImageCache()
    private var cache: [URL: NSImage] = [:]

    private init() {}

    func image(for url: URL) -> NSImage? {
        return cache[url]
    }

    func setImage(_ image: NSImage, for url: URL) {
        cache[url] = image
    }
}
extension ImageCache {
    func thumbnail(for url: URL, maxSize: CGFloat = 100) -> NSImage? {
        if let cached = cache[url] { return cached }

        guard let image = NSImage(contentsOf: url) else { return nil }
        let thumbnail = image.resized(toMax: maxSize)
        cache[url] = thumbnail
        return thumbnail
    }
}
extension NSImage {
    func resized(toMax maxSize: CGFloat) -> NSImage {
        let ratio = min(maxSize / size.width, maxSize / size.height)
        let newSize = NSSize(width: size.width * ratio, height: size.height * ratio)

        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        draw(in: NSRect(origin: .zero, size: newSize),
             from: NSRect(origin: .zero, size: size),
             operation: .copy,
             fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
}
