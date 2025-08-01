import SwiftUI

class ImagePageController: NSPageController, NSPageControllerDelegate {
    private var imagePaths: [URL] = []

    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.black.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        transitionStyle = .horizontalStrip
        NotificationCenter.default.addObserver(self, selector: #selector(openFolder), name: .openFolder, object: nil)
    }

    @objc func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            loadImages(from: url)
        }
    }

    func loadImages(from folder: URL) {
        let fileManager = FileManager.default
        if let items = try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
            imagePaths = items.filter { $0.pathExtension.lowercased() == "jpg" || $0.pathExtension.lowercased() == "png" }
            arrangedObjects = imagePaths
            selectedIndex = 0
        }
    }

    func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: String) -> NSViewController {
        return ImageViewController()
    }

    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> NSPageController.ObjectIdentifier {
        return "ImageViewController"
    }

    func pageController(_ pageController: NSPageController, prepare viewController: NSViewController, with object: Any?) {
        if let imageViewController = viewController as? ImageViewController, let url = object as? URL {
            imageViewController.setImage(url: url)
        }
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 124: // →
            navigateForward(nil)
        case 123: // ←
            navigateBack(nil)
        default:
            super.keyDown(with: event)
        }
    }
}
