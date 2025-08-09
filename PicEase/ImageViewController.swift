import AppKit

/// 単一の画像を表示し、ズームやパンなどのインタラクティブな操作を管理するビューコントローラです。
class ImageViewController: NSViewController {

    // MARK: - Properties

    var wrapper: PageControllerWrapper?

    /// 画像を表示するためのメインのビュー。
    var imageView = NSImageView()

    /// 現在表示している画像のURL。
    private var currentURL: URL?
    
    /// 現在のズーム倍率。1.0が等倍。
    private var zoomScale: CGFloat = 1.0
    
    /// スクロールナビゲーションのスロットリング用タイムスタンプ。
    private var lastScrollTime = Date.distantPast

    /// アプリケーションの設定を管理するストア。
    var settingsStore: SettingsStore?

    // MARK: - Lifecycle Methods

    /// ビューコントローラのビューをロードまたは作成します。
    /// ここでビューの階層、制約、ジェスチャー認識、コールバックを設定します。
    override func loadView() {
        // `imageView` の初期設定
        setupImageView()

        // ジェスチャーやマウスイベントをハンドリングするコンテナビューを作成
        let containerView = ZoomableImageViewContainer()
        containerView.wantsLayer = true // パフォーマンス向上のためレイヤーを有効化

        // imageViewをコンテナビューに追加
        containerView.addSubview(imageView)
        // このコントローラのメインビューとしてコンテナビューを設定
        self.view = containerView
        
        // Auto Layout制約を設定し、imageViewをコンテナビューいっぱいに広げる
        setupConstraints(for: imageView, in: containerView)

        // ジェスチャー認識とイベントハンドラを設定
        setupGestureRecognizers(in: containerView)
        setupEventHandlers(for: containerView)
    }

    // MARK: - Public Methods

    /// 指定されたURLから画像をロードして表示します。
    /// - Parameter url: 表示する画像のファイルURL。
    func setImage(url: URL) {
        self.currentURL = url
        // URLから画像を非同期ではなく直接ロード（ローカルファイルなので許容）
        imageView.image = NSImage(contentsOf: url)
        // 新しい画像が表示されたら、ズーム状態をリセット
        resetZoomState()
    }

    // MARK: - Setup Methods

    /// `imageView`のプロパティを初期化します。
    private func setupImageView() {
        // 画像のスケーリングモードを設定。アスペクト比を保ちつつ、ビューに収まるように拡大・縮小。
        imageView.imageScaling = .scaleProportionallyUpOrDown
        // Auto Layoutを有効にするため、`translatesAutoresizingMaskIntoConstraints`を`false`に設定。
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // パフォーマンス向上のためCore Animationレイヤーを有効化。
        imageView.wantsLayer = true
        imageView.canDrawSubviewsIntoLayer = true
        // ユーザーによる画像のコピー＆ペーストや編集を無効化。
        imageView.allowsCutCopyPaste = false
        imageView.isEditable = false
        // 画像をビューの中央に配置。
        imageView.imageAlignment = .alignCenter
    }

    /// 指定されたビューとその親ビューの間に制約を設定します。
    /// - Parameters:
    ///   - childView: 制約を設定する子ビュー。
    ///   - parentView: 制約の基準となる親ビュー。
    private func setupConstraints(for childView: NSView, in parentView: NSView) {
        NSLayoutConstraint.activate([
            // childViewの左端をparentViewの左端に合わせる
            childView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            // childViewの右端をparentViewの右端に合わせる
            childView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            // childViewの上端をparentViewの上端に合わせる
            childView.topAnchor.constraint(equalTo: parentView.topAnchor),
            // childViewの下端をparentViewの下端に合わせる
            childView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor)
        ])
    }

    /// ビューにジェスチャー認識を追加します。
    /// - Parameter targetView: ジェスチャー認識を追加するビュー。
    private func setupGestureRecognizers(in targetView: NSView) {
        // ダブルクリックジェスチャーを作成し、`handleDoubleClick`メソッドをターゲットに設定
        let doubleClickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(handleDoubleClick(_:)))
        doubleClickRecognizer.numberOfClicksRequired = 2
        targetView.addGestureRecognizer(doubleClickRecognizer)
        
        // シングルクリックジェスチャーを作成し、`handleSingleClick`メソッドをターゲットに設定
        let singleClickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(handleSingleClick(_:)))
        singleClickRecognizer.numberOfClicksRequired = 1
        targetView.addGestureRecognizer(singleClickRecognizer)
    }

    /// `ZoomableImageViewContainer`からのコールバックを設定します。
    /// - Parameter containerView: イベントハンドラを設定するコンテナビュー。
    private func setupEventHandlers(for containerView: ZoomableImageViewContainer) {
        // パン操作のコールバック。弱参照（`[weak self]`）で循環参照を防ぐ。
        containerView.onPan = { [weak self] delta in
            self?.handlePan(by: delta)
        }
        // ズーム操作のコールバック。
        containerView.onZoom = { [weak self] scaleDelta, location in
            self?.handleZoom(by: scaleDelta, at: location)
        }

        containerView.onScrollNavigate = { [weak self] direction in
            self?.handleScroll(for: direction)
        }
    }
    
    // MARK: - Event Handlers & Actions

    /// スクロールイベントに基づいて画像のナビゲーションを処理します。
    /// - Parameter direction: スクロールの方向（進む/戻る）。
    private func handleScroll(for direction: ScrollDirection) {
        // 設定で無効になっているか、スロットリング期間中の場合は何もしない
        guard let settingsStore = settingsStore, settingsStore.enableMouseWheel else { return }
        guard Date().timeIntervalSince(lastScrollTime) > 0.2, let wrapper = wrapper else { return }

        lastScrollTime = Date()

        switch direction {
        case .forward:
            if wrapper.selectedIndex < wrapper.imagePaths.count - 1 {
                wrapper.selectedIndex += 1
            } else {
                NotificationCenter.default.post(name: .shakeImage, object: nil)
            }
        case .backward:
            if wrapper.selectedIndex > 0 {
                wrapper.selectedIndex -= 1
            } else {
                NotificationCenter.default.post(name: .shakeImage, object: nil)
            }
        }
    }

    /// シングルクリックで呼び出され、UIの表示/非表示を切り替える通知を送信します。
    @objc func handleSingleClick(_ sender: NSClickGestureRecognizer) {
        guard let wrapper = wrapper, wrapper.isThumbnailVisible else { return }
        NotificationCenter.default.post(name: .hideThumbnail, object: nil)
    }
    
    /// ダブルクリックで呼び出され、ズームレベルを循環的に変更します。
    @objc private func handleDoubleClick(_ sender: NSClickGestureRecognizer) {
        // クリックされた位置をimageView内の座標に変換
        let location = sender.location(in: imageView)
        // ズームの中心点を設定
        setZoomAnchorPoint(at: location)
        // ズームレベルを次の段階（1x -> 2x -> 4x -> 1x）へ変更
        cycleZoomLevel()
    }
    
    /// ズーム状態を初期状態（1倍、中央揃え）にリセットします。
    private func resetZoomState() {
        // `imageView`のレイヤーを取得。存在しなければ何もしない。
        guard let layer = imageView.layer else { return }

        // ズーム倍率を1.0に戻す
        zoomScale = 1.0

        // レイヤーのアンカーポイント（変形の中心点）を中央(0.5, 0.5)にリセット
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        // レイヤーの位置をビューの中央にリセット
        layer.position = CGPoint(x: view.bounds.midX, y: view.bounds.midY)

        // `imageView`のトランスフォーム（変形）をリセット
        applyZoomTransform()
    }
    
    /// 指定された点を中心にズームするように、レイヤーのアンカーポイントを設定します。
    /// - Parameter point: ズームの中心としたい座標。
    private func setZoomAnchorPoint(at point: CGPoint) {
        guard let layer = imageView.layer else { return }
        
        let bounds = imageView.bounds
        // `point`が`bounds`内にあることを確認。`bounds`がゼロサイズの場合は処理を中断。
        guard bounds.width > 0, bounds.height > 0 else { return }

        // クリックされた位置を、ビューのサイズに対する相対的な割合（0.0〜1.0）に変換
        let anchorX = point.x / bounds.width
        let anchorY = point.y / bounds.height
        
        // アンカーポイントを計算した割合に設定
        layer.anchorPoint = CGPoint(x: anchorX, y: anchorY)
        // レイヤーの位置をクリックされたグローバル座標に設定
        layer.position = point
    }

    /// ズームレベルを 1x -> 2x -> 4x -> 1x の順で切り替えます。
    private func cycleZoomLevel() {
        // 現在のズームレベルに応じて次のレベルを決定
        switch zoomScale {
        case ..<1.5: // 1.5倍未満なら次は2倍
            zoomScale = 2.0
        case ..<3.5: // 3.5倍未満なら次は4倍
            zoomScale = 4.0
        default: // それ以外（4倍以上）なら1倍に戻す
            zoomScale = 1.0
        }
        
        // ズームレベルが1.0に戻った場合、アンカーポイントと位置を中央にリセット
        if zoomScale == 1.0 {
            resetAnchorPointToCenter()
        }

        // 計算された新しいズームレベルをビューに適用
        applyZoomTransform()
    }
    
    /// `zoomScale`プロパティに基づいて`imageView`のレイヤーにアフィン変形を適用します。
    private func applyZoomTransform() {
        // `zoomScale`に基づいて拡大・縮小の変形を作成
        let transform = CGAffineTransform(scaleX: zoomScale, y: zoomScale)
        // `imageView`のレイヤーにアフィン変形を設定
        imageView.layer?.setAffineTransform(transform)
    }
    
    /// 画像がズームされているときに、ドラッグ操作に応じて画像を移動（パン）させます。
    /// - Parameter delta: 前回の位置からの移動量。
    private func handlePan(by delta: NSPoint) {
        // ズームされていない場合はパン操作を無効化
        guard zoomScale > 1.0, let layer = imageView.layer else { return }
        
        // 現在のレイヤー位置に移動量を加算
        let currentPosition = layer.position
        let newPosition = CGPoint(x: currentPosition.x + delta.x, y: currentPosition.y + delta.y)
        
        // レイヤーの位置を更新
        layer.position = newPosition
    }
    
    /// マウスホイールやピンチ操作に応じて画像をズームします。
    /// - Parameters:
    ///   - scaleFactor: 拡大・縮小の倍率。
    ///   - point: ズーム操作の中心点。
    private func handleZoom(by scaleFactor: CGFloat, at point: CGPoint) {
        // 新しいズーム倍率を計算し、最小(0.1倍)と最大(10.0倍)の範囲内にクランプ
        zoomScale *= scaleFactor
        zoomScale = min(max(zoomScale, 0.1), 10.0)
        
        // ズームの中心点を設定
        setZoomAnchorPoint(at: point)
        
        // ズームレベルがほぼ1.0（閾値未満）になったら、中央にリセット
        if abs(zoomScale - 1.0) < 0.05 {
            zoomScale = 1.0
            resetAnchorPointToCenter()
        }
        
        // 新しいズーム倍率を適用
        applyZoomTransform()
    }

    /// レイヤーのアンカーポイントと位置をビューの中央にリセットします。
    private func resetAnchorPointToCenter() {
        guard let layer = imageView.layer else { return }
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.position = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
    }
}
