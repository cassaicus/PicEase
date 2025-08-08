import AppKit
import UniformTypeIdentifiers

/// 画像をページ形式で表示・管理するNSPageControllerのサブクラスです。
/// ファイルの読み込み、ページ間のナビゲーション、UI更新の通知などを担当します。
class ImagePageController: NSPageController, NSPageControllerDelegate {

    // MARK: - Properties

    /// アプリケーションの共有データ（画像URLリスト、選択インデックス）を管理するラッパーオブジェクト。
    private var wrapper: PageControllerWrapper

    /// キーボード入力の連続操作を防ぐためのロックフラグ。
    private var keyInputLocked = false
    
    // MARK: - Initialization

    /// PageControllerWrapperを注入してコントローラを初期化します。
    /// - Parameter controller: 共有データのラッパーインスタンス。
    init(controller: PageControllerWrapper) {
        self.wrapper = controller
        super.init(nibName: nil, bundle: nil)
    }
    
    /// StoryboardやXIBからの初期化はサポートしていません。
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle Methods

    /// ビューのロード時に呼び出されます。ビューの基本的なプロパティを設定します。
    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true // パフォーマンス向上のためレイヤーを有効化
        self.view.layer?.backgroundColor = NSColor.black.cgColor // 背景を黒に設定
    }
    
    /// ビューがロードされた後に呼び出されます。デリゲート、トランジションスタイル、通知の購読を設定します。
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.transitionStyle = .horizontalStrip // ページ遷移を横スライドに設定
        
        // アプリケーション全体からの通知を受け取るためのオブザーバーを登録
        setupNotificationObservers()
    }
    
    /// ビューが表示された後に呼び出されます。キーボード入力を受け付けるためにファーストレスポンダーになります。
    override func viewDidAppear() {
        super.viewDidAppear()
        // ウィンドウにキーボードイベントの最初の受信者になるよう要求
        view.window?.makeFirstResponder(self)
    }
    
    // MARK: - Notification Handling

    /// アプリケーション内で使用される各種通知のオブザーバーを一括で設定します。
    private func setupNotificationObservers() {
        let center = NotificationCenter.default
        // 各通知名に対応するセレクタ（メソッド）を登録
        center.addObserver(self, selector: #selector(handleOpenFolder), name: .openFolder, object: nil)
        center.addObserver(self, selector: #selector(handleOpenImage), name: .openImage, object: nil)
        center.addObserver(self, selector: #selector(handleOpenExternalImage(_:)), name: .openFromExternal, object: nil)
        center.addObserver(self, selector: #selector(handleOpenFolderFromBookmark(_:)), name: .openFolderFromBookmark, object: nil)
        center.addObserver(self, selector: #selector(handleThumbnailSelected(_:)), name: .thumbnailSelected, object: nil)
        center.addObserver(self, selector: #selector(handleRefreshCurrentPage), name: .refreshCurrentPage, object: nil)
        center.addObserver(self, selector: #selector(handleNavigateToIndex(_:)), name: .navigateToIndex, object: nil)
        center.addObserver(self, selector: #selector(openInFinder), name: .openFinder, object: nil)
    }

    @objc private func openInFinder() {
        guard !wrapper.imagePaths.isEmpty else { return }
        let currentURL = wrapper.imagePaths[wrapper.selectedIndex]
        NSWorkspace.shared.activateFileViewerSelecting([currentURL])
    }

    /// 「フォルダを開く」通知を処理します。
    @objc private func handleOpenFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true // フォルダ選択を許可
        panel.canChooseFiles = false // ファイル選択は不許可
        panel.allowsMultipleSelection = false // 複数選択は不許可
        
        // パネルが「OK」で閉じられ、URLが取得できた場合に処理を実行
        if panel.runModal() == .OK, let url = panel.url {
            loadImages(from: url)
        }
    }
    
    /// 「画像を開く」通知を処理します。
    @objc private func handleOpenImage() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true // ファイル選択を許可
        panel.canChooseDirectories = false // フォルダ選択は不許可
        panel.allowsMultipleSelection = false // 複数選択は不許可

        // UTTypeを使用して、許可するファイルタイプをモダンな方法で指定
        panel.allowedContentTypes = [.png, .jpeg, .gif, .bmp, .webP]

        // パネルが「OK」で閉じられ、URLが取得できた場合に処理を実行
        if panel.runModal() == .OK, let selectedURL = panel.url {
            // 選択された単一の画像をリストとして設定
            self.wrapper.setImages([selectedURL])
        }
    }

    /// 外部（Finderなど）から開かれた画像の通知を処理します。
    @objc private func handleOpenExternalImage(_ notification: Notification) {
        // 通知オブジェクトからURLの配列を取得
        guard let urls = notification.object as? [URL], let firstURL = urls.first else { return }

        // 最初のURLが含まれるディレクトリを取得
        let directoryURL = firstURL.hasDirectoryPath ? firstURL : firstURL.deletingLastPathComponent()

        // ディレクトリ内の全画像を読み込み、最初に指定された画像を初期選択状態にする
        loadImages(from: directoryURL, selecting: firstURL)
    }

    /// ブックマークからのフォルダ開封通知を処理します。
    @objc private func handleOpenFolderFromBookmark(_ notification: Notification) {
        // 通知オブジェクトからURLを取得
        guard let url = notification.object as? URL else { return }
        
        //NSFileReadNoPermissionErrorエラー回避の為にダイアログからフォルダーを選択
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true // フォルダ選択を許可
        panel.canChooseFiles = false // ファイル選択は不許可
        panel.allowsMultipleSelection = false // 複数選択は不許可
        panel.directoryURL = url //通知オブジェクトからのURLを指定
        
        // パネルが「OK」で閉じられ、URLが取得できた場合に処理を実行
        if panel.runModal() == .OK, let url = panel.url {
            loadImages(from: url)
        }
        
        
        // 指定されたURL（フォルダ）から画像を読み込む
        //loadImages(from: url)
    }

    /// サムネイル選択の通知を処理します。
    @objc private func handleThumbnailSelected(_ notification: Notification) {
        // 通知オブジェクトからインデックスを取得し、ページをそのインデックスに切り替え
        if let index = notification.object as? Int, index >= 0, index < arrangedObjects.count {
            selectedIndex = index
        }
    }
    
    /// インデックス指定ナビゲーションの通知を処理します。
    @objc private func handleNavigateToIndex(_ notification: Notification) {
        if let index = notification.object as? Int, arrangedObjects.indices.contains(index) {
            // 現在のインデックスと異なるときだけ実行
            if selectedIndex != index {
                selectedIndex = index
            }
        }
    }

    /// 現在表示中のページを強制的に再描画する通知を処理します。
    @objc private func handleRefreshCurrentPage() {
        let count = arrangedObjects.count
        let currentIndex = selectedIndex

        // 表示中の画像がない場合は何もしない
        guard count > 0 else { return }

        // この処理は、NSPageControllerがビューの更新を正しく反映しない場合があるための回避策（ハック）です。
        // 特に、画像のサイズが変わった場合や、外部でファイルが変更された場合に有効です。
        
        if count == 1 {
            // 画像が1枚しかない場合：
            // 一時的に無効なダミーURLを設定し、即座に元のURLに戻すことで、ビューのリロードを強制します。
            let originalURLs = self.wrapper.imagePaths
            let dummyURL = URL(fileURLWithPath: "/dev/null") // 無効なURL
            self.wrapper.setImages([dummyURL])
            
            // メインスレッドの次のサイクルで元のURLリストに戻す
            DispatchQueue.main.async {
                self.wrapper.setImages(originalURLs)
            }
        } else {
            // 画像が複数ある場合：
            // 選択インデックスを一時的に別のインデックスに変更し、すぐに元に戻すことで再描画をトリガーします。
            // これにより、現在のページの`viewController`が再生成または再設定されることを期待しています。
            let targetIndex = currentIndex == 0 ? 1 : 0 // 現在が0なら1、それ以外なら0
            self.selectedIndex = targetIndex
            self.selectedIndex = currentIndex // すぐに元に戻す
        }
    }
    
    // MARK: - Image Loading

    /// 指定されたフォルダURLから画像を非同期で読み込み、ビューを更新します。
    /// - Parameters:
    ///   - folderURL: 画像が含まれるフォルダのURL。
    ///   - initialURL: 初期状態で選択したい画像のURL（オプショナル）。
    private func loadImages(from folderURL: URL, selecting initialURL: URL? = nil) {
        // ファイルI/Oは重い可能性があるため、バックグラウンドスレッドで実行
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // FileManagerを使用してディレクトリの内容を取得
                let allItems = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)

                // ユーティリティ関数を使って画像ファイルのみをフィルタリング＆ソート
                let imageURLs = ImageFileUtility.filterAndSortImageURLs(from: allItems)

                // UI更新はメインスレッドで行う
                DispatchQueue.main.async {
                    if imageURLs.isEmpty {
                        // 画像が見つからなかった場合はアラートを表示
                        self.showAlert(title: "画像がありません", message: "このフォルダにはサポートされている画像ファイルがありません。")
                        return
                    }
                    
                    // 初期選択インデックスを決定
                    let initialIndex = initialURL.flatMap { imageURLs.firstIndex(of: $0) } ?? 0
                    
                    // wrapperに画像リストと選択インデックスを設定してUIを更新
                    self.wrapper.setImagesIndex(imageURLs, initialIndex)
                }
            } catch {
                // エラーが発生した場合は、コンソールに出力し、アラートを表示
                print("Error loading images: \(error)")
                DispatchQueue.main.async {
                    self.showAlert(title: "エラー", message: "フォルダの内容を読み込めませんでした。")
                }
            }
        }
    }
    
    /// ユーザーに情報を伝えるためのアラートを表示します。
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }

    // MARK: - NSPageControllerDelegate
    
    /// 各ページ（オブジェクト）に対応する一意の識別子を返します。
    func pageController(_ pageController: NSPageController, identifierFor object: Any) -> NSPageController.ObjectIdentifier {
        // すべてのページで同じタイプのビューコントローラを使用するため、固定の識別子を返す
        return "ImageViewController"
    }
    
    /// 指定された識別子に対応するビューコントローラをインスタンス化して返します。
    func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: String) -> NSViewController {
        // 新しいImageViewControllerを生成
        let vc = ImageViewController()
        vc.wrapper = self.wrapper
        return vc
    }
    
    /// ビューコントローラが画面に表示される直前に呼び出されます。ここでビューコントローラにデータを渡します。
    func pageController(_ pageController: NSPageController, prepare viewController: NSViewController, with object: Any?) {
        // `object`（この場合はURL）をImageViewControllerにキャストして、画像を設定
        if let vc = viewController as? ImageViewController, let url = object as? URL {
            vc.setImage(url: url)
        }
    }
    
    /// ページ遷移が完了した後に呼び出されます。
    func pageController(_ pageController: NSPageController, didTransitionTo object: Any) {
        // 新しく表示されたページのオブジェクト（URL）からインデックスを見つけ、共有データを更新
        if let url = object as? URL, let index = wrapper.imagePaths.firstIndex(of: url) {
            // UIの状態とデータの状態を同期させる
            self.wrapper.selectedIndex = index
        }
    }
    
    /// ライブトランジション（ユーザーがドラッグ中など）が終了したときに呼び出されます。
    func pageControllerDidEndLiveTransition(_ pageController: NSPageController) {
        // トランジションを確定させる
        pageController.completeTransition()
    }
    
    // MARK: - Keyboard Handling

    /// キーボードのキーが押されたときに呼び出されます。左右の矢印キーでページをナビゲートします。
    override func keyDown(with event: NSEvent) {
        // 短時間での連続入力を防ぐためのロック
        guard !keyInputLocked else { return }
        
        // `keyCode`に基づいて処理を分岐
        switch event.keyCode {
        case 124: // 右矢印キー
            navigateForward(nil)
        case 123: // 左矢印キー
            navigateBack(nil)
        default:
            // 他のキー入力はデフォルトの動作に任せる
            super.keyDown(with: event)
            return // navigateメソッドが呼ばれなかった場合は、ロックをかけずに即座にリターン
        }
        
        // ナビゲーションが実行された場合、キー入力を一時的にロック
        keyInputLocked = true
        // 0.2秒後にロックを解除
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.keyInputLocked = false
        }
    }

    /// このビューコントローラがキーイベントの最初の受信者になれることを示します。
    override var acceptsFirstResponder: Bool { true }
}
