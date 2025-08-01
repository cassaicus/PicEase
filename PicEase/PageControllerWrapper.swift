import Foundation

class PageControllerWrapper: ObservableObject {
    @Published var imagePaths: [URL] = [] {
        didSet {
            if selectedIndex >= imagePaths.count {
                selectedIndex = max(0, imagePaths.count - 1)
            }
        }
    }
    @Published var selectedIndex: Int = 0 {
        didSet {
            if selectedIndex >= imagePaths.count {
                selectedIndex = max(0, imagePaths.count - 1)
            }
        }
    }

    func setImages(_ urls: [URL]) {
        imagePaths = urls
        selectedIndex = 0
    }
}
