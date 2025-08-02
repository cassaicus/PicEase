// AppKit フレームワークをインポート
import AppKit

// NSPageController を継承し、デリゲートメソッドを実装するクラスを定義
class ImagePageController: NSPageController, NSPageControllerDelegate {
    // PageControllerWrapper のインスタンスを保持し、データソースと同期する
    private var wrapper: PageControllerWrapper
    // ラッパーを注入してイニシャライザを呼び出す
    init(controller: PageControllerWrapper) {
        self.wrapper = controller
        super.init(nibName: nil, bundle: nil)
    }
    // Interface Builder からの初期化を許可せず、未実装としてクラッシュさせる
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // ビュー階層をコードで構築し、背景色を黒に設定
    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.black.cgColor
    }
    // ビューがロードされた後にデリゲート設定と通知購読を行う
    override func viewDidLoad() {
        // スーパークラスの viewDidLoad を呼び出し、基本初期化を実行
        super.viewDidLoad()
        // ページコントローラーのデリゲートを self に設定
        delegate = self
        // ページ遷移スタイルを横スクロールに指定
        transitionStyle = .horizontalStrip
        // 「フォルダーを開く」通知を購読し、受信時に openFolder() を呼び出す
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(openFolder),
                                               name: .openFolder,
                                               object: nil)
        // サムネイル選択通知を購読し、受信時に thumbnailSelected(_:) を呼び出す
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(thumbnailSelected(_:)),
                                               name: .thumbnailSelected,
                                               object: nil)
    }

    // ウィンドウ表示直後に自コントローラーをファーストレスポンダーに設定
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(self)
    }
    // フォルダ選択パネルを開き、画像ファイルを非同期で読み込む
    // フォルダを開くアクションとして Objective-C ランタイムから呼び出し可能にする
    @objc func openFolder() {
        // フォルダ選択用のダイアログパネルを生成
        let panel = NSOpenPanel()
        // ディレクトリのみ選択可能に設定
        panel.canChooseDirectories = true
        // ファイルは選択不可に設定
        panel.canChooseFiles = false
        // 複数選択を許可しない
        panel.allowsMultipleSelection = false
        // モーダル表示し、ユーザーが「OK」を押したかつ URL が取得できた場合のみ処理を実行
        if panel.runModal() == .OK, let url = panel.url {
            // 画像ファイルの読み込みとソートをバックグラウンドスレッドで実行
            DispatchQueue.global(qos: .userInitiated).async {
                // ファイルマネージャを取得
                let fm = FileManager.default
                // 選択したディレクトリ内のアイテム一覧を取得（隠しファイルはスキップ）
                let items = try? fm.contentsOfDirectory(at: url,
                                                        includingPropertiesForKeys: nil,
                                                        options: [.skipsHiddenFiles])
                // 画像拡張子のみフィルタし、ファイル名でソート
                let images = items?
                    .filter { ["jpg","jpeg","png","gif","bmp","webp"]
                        .contains($0.pathExtension.lowercased()) }
                    .sorted {
                        $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent)
                        == .orderedAscending
                    } ?? []
                // メインスレッドに戻して UI（データモデル）を更新
                DispatchQueue.main.async {
                    // PageControllerWrapper に画像 URL 配列をセット
                    self.wrapper.setImages(images)
                }
            }
        }
    }

    // サムネイル選択通知を受け取り、対応するページに遷移
    // Objective-C ランタイムから呼び出せるサムネイル選択ハンドラ
    @objc func thumbnailSelected(_ notification: Notification) {
        // 通知オブジェクトから Int 型のインデックスを取得しようと試みる
        if let index = notification.object as? Int,
           // インデックスが 0 以上であることをチェック
           index >= 0,
           // インデックスが配置済みオブジェクト数より小さいことをチェック
           index < arrangedObjects.count {
            // PageController の選択インデックスを更新
            selectedIndex = index
            // ページ遷移を明示的に完了させ、ビューを再描画
            completeTransition()
        }
    }

    // オブジェクト（URL）に対応するページ識別子を返す
    func pageController(_ pageController: NSPageController,
                        identifierFor object: Any) -> NSPageController.ObjectIdentifier {
        return "ImageViewController"
    }
    // 指定された識別子に合致するビューコントローラーを生成
    func pageController(_ pageController: NSPageController,
                        viewControllerForIdentifier identifier: String) -> NSViewController {
        return ImageViewController()
    }
    // ビューコントローラーに表示すべき画像 URL をセット
    func pageController(_ pageController: NSPageController,
                        prepare viewController: NSViewController,
                        with object: Any?) {
        if let vc = viewController as? ImageViewController,
           let url = object as? URL {
            vc.setImage(url: url)
        }
    }
    // ページ遷移完了後に選択中インデックスを更新して同期
    func pageController(_ pageController: NSPageController,
                        didTransitionTo object: Any) {
        if let url = object as? URL,
           let index = wrapper.imagePaths.firstIndex(of: url) {
            wrapper.selectedIndex = index
        }
    }
    // ライブ遷移終了時に遷移を確定させる
    func pageControllerDidEndLiveTransition(_ pageController: NSPageController) {
        pageController.completeTransition()
    }
    // 矢印キー入力で前後のページへナビゲートするハンドリング
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        //右キー
        case 124: navigateForward(nil)
        //左キー
        case 123: navigateBack(nil)
        default: super.keyDown(with: event)
        }
    }

    // ファーストレスポンダーとしてキーボードイベントを受け付ける設定
    override var acceptsFirstResponder: Bool { true }
}
