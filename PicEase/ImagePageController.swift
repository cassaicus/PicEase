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
        self.view.layer?.backgroundColor = NSColor.black.cgColor // 背景黒
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        transitionStyle = .horizontalStrip // 横スクロール
        
        // 通知を購読
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openFolderFromBookmark(_:)),
            name: .openFolderFromBookmark,
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
            selector: #selector(thumbnailSelected(_:)),
            name: .thumbnailSelected,
            object: nil)
    }
    

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(self)
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
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        //var optionURLS = true
        
//        if let url = notification.object as? URL {
//            if optionURLS {
//                //単体画像として開く
//                wrapper.setImages([url])
//            } else {
//                // 最初のURLが存在しなければ処理終了
//                guard let selectedFileURL = notification.object as? URL else { return }
//                // 対象ファイルのあるフォルダのURLを取得
//                let folderURL = selectedFileURL.deletingLastPathComponent()
//                // フォルダ選択ダイアログのインスタンス生成
//                let panel = NSOpenPanel()
//                // ファイル選択を不可に
//                panel.canChooseFiles = false
//                // フォルダ選択を可能に
//                panel.canChooseDirectories = true
//                // 複数選択不可
//                panel.allowsMultipleSelection = false
//                // ダイアログのボタン名
//                panel.prompt = "Select"
//                // 初期ディレクトリを設定（現在のファイルのフォルダ）
//                panel.directoryURL = folderURL
//                
//                // フォルダが選択された場合のみ処理を続ける
//                if panel.runModal() == .OK, let confirmedFolder = panel.url {
//                    // 対応する画像拡張子の配列
//                    let allowedExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "webp"]
//                    
//                    // フォルダ内のすべてのファイルを取得（隠しファイルは除外）
//                    if let files = try? FileManager.default.contentsOfDirectory(
//                        at: confirmedFolder,
//                        includingPropertiesForKeys: nil,
//                        options: [.skipsHiddenFiles]
//                    ) {
//                        // 対象となる画像ファイルだけをフィルタして並べ替える
//                        let imageFiles = files
//                            .filter { allowedExtensions.contains($0.pathExtension.lowercased()) }
//                        //Finder風の自然順ソート
//                            .sorted {
//                                $0.lastPathComponent
//                                    .localizedStandardCompare($1.lastPathComponent)
//                                == .orderedAscending
//                            }
//                        // 一枚も画像がなければ終了
//                        guard !imageFiles.isEmpty else { return }
//                        
//                        print("imageFiles")
//                    }
//                }
//            }
//        }
        
        
    }
    
//    @objc func openExternalImage(_ notification: Notification) {
//        print("openExternalImage")
//        var optionURLS = true
//        
//        if let url = notification.object as? URL {
//            if optionURLS {
//                //単体画像として開く
//                wrapper.setImages([url])
//            } else {
//                // 最初のURLが存在しなければ処理終了
//                guard let selectedFileURL = notification.object as? URL else { return }
//                // 対象ファイルのあるフォルダのURLを取得
//                let folderURL = selectedFileURL.deletingLastPathComponent()
//                // フォルダ選択ダイアログのインスタンス生成
//                let panel = NSOpenPanel()
//                // ファイル選択を不可に
//                panel.canChooseFiles = false
//                // フォルダ選択を可能に
//                panel.canChooseDirectories = true
//                // 複数選択不可
//                panel.allowsMultipleSelection = false
//                // ダイアログのボタン名
//                panel.prompt = "Select"
//                // 初期ディレクトリを設定（現在のファイルのフォルダ）
//                panel.directoryURL = folderURL
//                
//                // フォルダが選択された場合のみ処理を続ける
//                if panel.runModal() == .OK, let confirmedFolder = panel.url {
//                    // 対応する画像拡張子の配列
//                    let allowedExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "webp"]
//                    
//                    // フォルダ内のすべてのファイルを取得（隠しファイルは除外）
//                    if let files = try? FileManager.default.contentsOfDirectory(
//                        at: confirmedFolder,
//                        includingPropertiesForKeys: nil,
//                        options: [.skipsHiddenFiles]
//                    ) {
//                        // 対象となる画像ファイルだけをフィルタして並べ替える
//                        let imageFiles = files
//                            .filter { allowedExtensions.contains($0.pathExtension.lowercased()) }
//                        //Finder風の自然順ソート
//                            .sorted {
//                                $0.lastPathComponent
//                                    .localizedStandardCompare($1.lastPathComponent)
//                                == .orderedAscending
//                            }
//                        // 一枚も画像がなければ終了
//                        guard !imageFiles.isEmpty else { return }
//                        
//                        print("imageFiles")
//                    }
//                }
//            }
//        }
//    }

    
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
                        self.wrapper.setImages(images)
                    }
                }
            }
        }
    }
    
    
    
//    @objc func openfo(_ urls: [URL]) {
//        guard let firstURL = urls.first else { return }
//        let folderURL = firstURL.deletingLastPathComponent()
//        
//        let panel = NSOpenPanel()
//        panel.canChooseDirectories = true
//        panel.canChooseFiles = false
//        panel.allowsMultipleSelection = false
//        panel.prompt = "Select"
//        panel.directoryURL = folderURL // ここが目的の指定
//        
//        if panel.runModal() == .OK, let url = panel.url {
//            DispatchQueue.global(qos: .userInitiated).async {
//                let fm = FileManager.default
//                let items = try? fm.contentsOfDirectory(
//                    at: url,
//                    includingPropertiesForKeys: nil,
//                    options: [.skipsHiddenFiles]
//                )
//                
//                let images = items?.filter {
//                    ["jpg", "jpeg", "png", "gif", "bmp", "webp"]
//                        .contains($0.pathExtension.lowercased())
//                }.sorted {
//                    $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
//                } ?? []
//                
//                DispatchQueue.main.async {
//                    self.wrapper.setImages(images)
//                }
//            }
//        }
//    }
    
    
//    @objc func openfou(_ notification: URL) {
//        print("openfou")
//        var optionURLS = false
//        
//        if let url = notification as? URL {
//            if optionURLS {
//                //単体画像として開く
//                wrapper.setImages([url])
//            } else {
//                // 最初のURLが存在しなければ処理終了
//                guard let selectedFileURL = notification as? URL else { return }
//                // 対象ファイルのあるフォルダのURLを取得
//                let folderURL = selectedFileURL.deletingLastPathComponent()
//                // フォルダ選択ダイアログのインスタンス生成
//                let panel = NSOpenPanel()
//                // ファイル選択を不可に
//                panel.canChooseFiles = false
//                // フォルダ選択を可能に
//                panel.canChooseDirectories = true
//                // 複数選択不可
//                panel.allowsMultipleSelection = false
//                // ダイアログのボタン名
//                panel.prompt = "Select"
//                // 初期ディレクトリを設定（現在のファイルのフォルダ）
//                panel.directoryURL = folderURL
//                
//                // フォルダが選択された場合のみ処理を続ける
//                if panel.runModal() == .OK, let confirmedFolder = panel.url {
//                    // 対応する画像拡張子の配列
//                    let allowedExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "webp"]
//                    
//                    // フォルダ内のすべてのファイルを取得（隠しファイルは除外）
//                    if let files = try? FileManager.default.contentsOfDirectory(
//                        at: confirmedFolder,
//                        includingPropertiesForKeys: nil,
//                        options: [.skipsHiddenFiles]
//                    ) {
//                        // 対象となる画像ファイルだけをフィルタして並べ替える
//                        let imageFiles = files
//                            .filter { allowedExtensions.contains($0.pathExtension.lowercased()) }
//                        //Finder風の自然順ソート
//                            .sorted {
//                                $0.lastPathComponent
//                                    .localizedStandardCompare($1.lastPathComponent)
//                                == .orderedAscending
//                            }
//                        // 一枚も画像がなければ終了
//                        //guard !imageFiles.isEmpty else { return }
//                        
//                        print(imageFiles)
//                        
//                        
//                        self.wrapper.setImages(imageFiles)
//                        
//                    }
//                }
//            }
//        }
//    }
    
    
    
//    @objc func openFolder() {
//        let panel = NSOpenPanel()
//        panel.canChooseDirectories = true
//        panel.canChooseFiles = false
//        panel.allowsMultipleSelection = false
//        
//        if panel.runModal() == .OK, let url = panel.url {
//            DispatchQueue.global(qos: .userInitiated).async {
//                let fm = FileManager.default
//                let items = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
//                
//                let images = items?.filter {
//                    ["jpg", "jpeg", "png", "gif", "bmp", "webp"]
//                        .contains($0.pathExtension.lowercased())
//                }.sorted {
//                    $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
//                } ?? []
//                
//                DispatchQueue.main.async {
//                    self.wrapper.setImages(images)
//                }
//            }
//        }
//    }
    
    
    
    
    
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
}


//
//class ImagePageControllerWrapper: ObservableObject {
//    let controller: ImagePageController
//    
//    init(model: PageControllerWrapper) {
//        controller = ImagePageController(controller: model)
//    }
//    func openFolder(_ url: URL) {
//        controller.openFolder()
//    }
//}
