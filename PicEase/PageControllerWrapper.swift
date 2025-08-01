import SwiftUI
import Foundation

// ページコントロール用のデータ管理クラス
class PageControllerWrapper: ObservableObject {
    @Published var imagePaths: [URL] = [] {
        didSet {
            preloadImages(around: selectedIndex)
        }
    }

    @Published var selectedIndex: Int = 0 {
        didSet {
            preloadImages(around: selectedIndex)
        }
    }

    func setImages(_ urls: [URL]) {
        imagePaths = urls
        selectedIndex = 0
    }

    private func preloadImages(around index: Int) {
        let range = (index - 2)...(index + 2)
        for i in range {
            guard imagePaths.indices.contains(i) else { continue }
            let url = imagePaths[i]
            if ImageCache.shared.image(for: url) == nil {
                if let img = NSImage(contentsOf: url) {
                    ImageCache.shared.setImage(img, for: url)
                }
            }
        }
    }
}
