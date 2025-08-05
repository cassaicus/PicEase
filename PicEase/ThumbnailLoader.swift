import AppKit
import Combine

class ThumbnailLoader: ObservableObject {
    @Published var image: NSImage? = nil
    private var cancellable: AnyCancellable?

    func load(from url: URL, maxSize: CGFloat = 100) {
        if let cached = ImageCache.shared.image(for: url) {
            self.image = cached
            return
        }

        cancellable = Just(url)
            // 遅延
            .delay(for: .milliseconds(50), scheduler: DispatchQueue.global(qos: .background))
            .map { url in
                guard let img = NSImage(contentsOf: url) else { return nil }
                let thumb = img.resized(toMax: maxSize)
                ImageCache.shared.setImage(thumb, for: url)
                return thumb
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] img in
                self?.image = img
            }
    }
}
