// ImagePageController.swift
import AppKit

class ImagePageController: NSPageController, NSPageControllerDelegate {
    private var wrapper: PageControllerWrapper

    init(controller: PageControllerWrapper) {
        self.wrapper = controller
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        NotificationCenter.default.addObserver(self, selector: #selector(thumbnailSelected(_:)), name: .thumbnailSelected, object: nil)
    }
    
    override func viewDidAppear() {
       super.viewDidAppear()
       view.window?.makeFirstResponder(self)
    }


    @objc func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            let fm = FileManager.default
            let items = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            //let images = items?.filter { ["jpg", "png", "jpeg"].contains($0.pathExtension.lowercased()) } ?? []
            
            let images = items?.filter {
                ["jpg", "jpeg", "png", "gif", "bmp", "webp"].contains($0.pathExtension.lowercased())
            }.sorted {
                $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
            } ?? []
            
            wrapper.setImages(images)
        }
    }

    @objc func thumbnailSelected(_ notification: Notification) {
        if let index = notification.object as? Int,
           index >= 0,
           index < arrangedObjects.count {
            selectedIndex = index
        }
    }

    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> NSPageController.ObjectIdentifier {
        return "ImageViewController"
    }

    func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: String) -> NSViewController {
        return ImageViewController()
    }

    func pageController(_ pageController: NSPageController, prepare viewController: NSViewController, with object: Any?) {
        if let vc = viewController as? ImageViewController, let url = object as? URL {
            vc.setImage(url: url)
        }
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 124: navigateForward(nil) // →
        case 123: navigateBack(nil)    // ←
        default: super.keyDown(with: event)
        }
    }

    override var acceptsFirstResponder: Bool { true }
}
