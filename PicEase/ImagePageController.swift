import AppKit

class ImagePageController: NSPageController, NSPageControllerDelegate {
    private var wrapper: PageControllerWrapper

    // 初期化時にデータラッパーを注入
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
        self.view.layer?.backgroundColor = NSColor.black.cgColor // 背景黒
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        transitionStyle = .horizontalStrip // 横スクロール

        // 通知を購読
        NotificationCenter.default.addObserver(self, selector: #selector(openFolder), name: .openFolder, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(thumbnailSelected(_:)), name: .thumbnailSelected, object: nil)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(self)
    }

    // フォルダー選択パネルを表示
    @objc func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            let fm = FileManager.default
            let items = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            let images = items?.filter {
                ["jpg", "jpeg", "png", "gif", "bmp", "webp"]
                    .contains($0.pathExtension.lowercased())
            }.sorted {
                $0.lastPathComponent
                    .localizedStandardCompare($1.lastPathComponent)
                == .orderedAscending
            } ?? []
            
            wrapper.setImages(images) // ラッパーに画像を渡す
        }
    }

    // サムネイルが選択されたときの処理
    @objc func thumbnailSelected(_ notification: Notification) {
        if let index = notification.object as? Int,
           index >= 0,
           index < arrangedObjects.count {
            selectedIndex = index
        }
    }

    // 各ページの識別子
    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> NSPageController.ObjectIdentifier {
        return "ImageViewController"
    }

    // 指定識別子に対応するビューコントローラーを返す
    func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: String) -> NSViewController {
        return ImageViewController()
    }

    // 各ビューコントローラーに画像をセット
    func pageController(_ pageController: NSPageController, prepare viewController: NSViewController, with object: Any?) {
        if let vc = viewController as? ImageViewController, let url = object as? URL {
            vc.setImage(url: url)
        }
    }

    // キーボード操作（←→）でナビゲート可能に
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 124: navigateForward(nil) // →
        case 123: navigateBack(nil)    // ←
        default: super.keyDown(with: event)
        }
    }

    override var acceptsFirstResponder: Bool { true } // キー入力を受け付ける
}
