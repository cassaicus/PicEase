import SwiftUI

final class ImageCache {
    static let shared = ImageCache()

    private let queue = DispatchQueue(label: "jp.gptjp.imagecache", attributes: .concurrent)
    private var cache: [URL: NSImage] = [:]

    private init() {}

    func image(for url: URL) -> NSImage? {
        var result: NSImage?
        queue.sync {
            result = cache[url]
        }
        return result
    }

    func setImage(_ image: NSImage, for url: URL) {
        queue.async(flags: .barrier) {
            self.cache[url] = image
        }
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
