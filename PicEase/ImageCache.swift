import SwiftUI

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
