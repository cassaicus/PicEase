import AppKit

class ImagePageController: NSPageController, NSPageControllerDelegate {
    private var wrapper: PageControllerWrapper
    private var keyInputLocked = false
    
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
        // 背景黒
        self.view.layer?.backgroundColor = NSColor.black.cgColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        // 横スクロール
        transitionStyle = .horizontalStrip
        
        // 通知を購読
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openFolder),
            name: .openFolder,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openExternalImage(_:)),
            name: .openFromExternal,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openFolderFromBookmark(_:)),
            name: .openFolderFromBookmark,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(thumbnailSelected(_:)),
            name: .thumbnailSelected,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshCurrentPage),
            name: .refreshCurrentPage,
            object: nil
        )
        
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
            DispatchQueue.global(qos: .userInitiated).async {
                let fm = FileManager.default
                let items = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                
                let images = items?.filter {
                    ["jpg", "jpeg", "png", "gif", "bmp", "webp"]
                        .contains($0.pathExtension.lowercased())
                }.sorted {
                    $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
                } ?? []
                
                DispatchQueue.main.async {
                    if images.isEmpty {
                        //アラート表示
                        let alert = NSAlert()
                        alert.messageText = "NO image"
                        alert.informativeText = "this folder has no image"
                        alert.alertStyle = .warning
                        alert.runModal()
                        return
                    }
                    
                    self.wrapper.setImages(images)
                }
            }
        }
    }
    
    @objc func openExternalImage(_ notification: Notification) {
        print("openExternalImage")
        
        //var nopanel = true
        
        if let url = notification.object as? URL {
            let urls = [url]
            guard let folderURL = urls.first else { return }
            let panel = NSOpenPanel()
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            panel.allowsMultipleSelection = false
            panel.prompt = "Select"
            panel.directoryURL = folderURL
            
            if panel.runModal() == .OK, let url = panel.url {
                DispatchQueue.global(qos: .userInitiated).async {
                    let fm = FileManager.default
                    let items = try? fm.contentsOfDirectory(
                        at: url,
                        includingPropertiesForKeys: nil,
                        options: [.skipsHiddenFiles]
                    )
                    
                    let images = items?.filter {
                        ["jpg", "jpeg", "png", "gif", "bmp", "webp"]
                            .contains($0.pathExtension.lowercased())
                    }.sorted {
                        $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
                    } ?? []
                    
                    let currentIndex = images.firstIndex(of: folderURL) ?? 0
                    
                    DispatchQueue.main.async {
                        self.wrapper.setImagesIndex(images,currentIndex)
                    }
                }
            }else{
                //単体画像として開く
                self.wrapper.setImages([url])
            }
        }
    }
    
    @objc func openFolderFromBookmark(_ notification: Notification) {
        if let url = notification.object as? URL {
            let urls = [url]
            guard let folderURL = urls.first else { return }
            let panel = NSOpenPanel()
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            panel.allowsMultipleSelection = false
            panel.prompt = "Select"
            panel.directoryURL = folderURL
            
            if panel.runModal() == .OK, let url = panel.url {
                DispatchQueue.global(qos: .userInitiated).async {
                    let fm = FileManager.default
                    let items = try? fm.contentsOfDirectory(
                        at: url,
                        includingPropertiesForKeys: nil,
                        options: [.skipsHiddenFiles]
                    )
                    
                    let images = items?.filter {
                        ["jpg", "jpeg", "png", "gif", "bmp", "webp"]
                            .contains($0.pathExtension.lowercased())
                    }.sorted {
                        $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
                    } ?? []
                    
                    DispatchQueue.main.async {
                        if images.isEmpty {
                            //アラート表示
                            let alert = NSAlert()
                            alert.messageText = "NO image"
                            alert.informativeText = "this folder has no image"
                            alert.alertStyle = .warning
                            alert.runModal()
                            return
                        }
                        self.wrapper.setImages(images)
                    }
                }
            }
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
    
    func pageController(_ pageController: NSPageController, didTransitionTo object: Any) {
        if let url = object as? URL,
           let index = wrapper.imagePaths.firstIndex(of: url) {
            // Viewの更新が終わったあとに状態変更を遅延させる
            DispatchQueue.main.async {
                self.wrapper.selectedIndex = index
            }
        }
    }
    
    // キーボード操作（←→）でナビゲート可能に
    override func keyDown(with event: NSEvent) {
        // 入力ロック中なら無視
        guard !keyInputLocked else { return }
        // ロック開始
        keyInputLocked = true
        //判定
        switch event.keyCode {
        // →
        case 124: navigateForward(nil)
        // ←
        case 123: navigateBack(nil)
        default: super.keyDown(with: event)
        }
        // 一定時間後にロック解除（例：0.2秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.keyInputLocked = false
        }
    }
    override var acceptsFirstResponder: Bool { true } // キー入力を受け付ける

    func pageControllerDidEndLiveTransition(_ pageController: NSPageController) {
        pageController.completeTransition()
    }    
    
    @objc func refreshCurrentPage() {
        let count = arrangedObjects.count
        let idx = selectedIndex

        guard count > 0 else { return }

        if count == 1 {
            // 画像が1枚だけなら index を変えずに再設定
            selectedIndex = idx
            return
        }

        if idx + 1 < count {
            selectedIndex = idx + 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.selectedIndex = idx
            }
        } else if idx > 0 {
            selectedIndex = idx - 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.selectedIndex = idx
            }
        }
    }

}
