// AppKit フレームワークをインポートして macOS UI コンポーネントを利用可能にする
import AppKit

// NSViewController を継承した画像表示用ビューコントローラを定義
class ImageViewController: NSViewController {
    // 画像を表示する NSImageView インスタンスをプロパティに保持
    private var imageView = NSImageView()
    // 現在のズーム倍率を保持（初期値 1.0）
    private var zoomScale: CGFloat = 1.0

    // ビューコントローラのルートビューをプログラムでセットアップするメソッド
    override func loadView() {
        // ズーム＆パン可能なコンテナビューを生成
        let containerView = ZoomableImageViewContainer()
        // コンテナビューに Core Animation レイヤーを持たせる
        containerView.wantsLayer = true

        // 画像の拡大縮小方法を保持比率で上下に合わせる設定
        imageView.imageScaling = .scaleProportionallyUpOrDown
        // Auto Layout 制約を使えるようにする
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // 画像ビューにもレイヤーを持たせる
        imageView.wantsLayer = true
        // 画像の配置をビュー中央に揃える
        imageView.imageAlignment = .alignCenter

        // コンテナビューに画像ビューを追加
        containerView.addSubview(imageView)
        // このコントローラのルートビューをコンテナビューに設定
        view = containerView

        // 画像ビューをコンテナの全領域にフィットさせる制約を有効化
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        // ダブルクリック検出用ジェスチャーを生成
        let doubleClick = NSClickGestureRecognizer(target: self, action: #selector(handleDoubleClick(_:)))
        // 必要なクリック数を 2 回に設定
        doubleClick.numberOfClicksRequired = 2
        // コンテナビューにジェスチャーを登録
        containerView.addGestureRecognizer(doubleClick)

        // ズーム操作のコールバックを設定
        containerView.onZoom = { [weak self] scaleDelta, location in
            // ズームイベントが起きたら zoom(by:at:) を呼び出す
            self?.zoom(by: scaleDelta, at: location)
        }
        // パン操作のコールバックを設定
        containerView.onPan = { [weak self] delta in
            // パンイベントが起きたら pan(by:) を呼び出す
            self?.pan(by: delta)
        }
    }

    // 外部から画像を設定するパブリックメソッド
    func setImage(url: URL) {
        // URL から NSImage を読み込んで imageView にセット
        imageView.image = NSImage(contentsOf: url)
        // 新しい画像に合わせてズーム状態をリセット
        //resetZoom()
        // 🔧 拡大中心とパン状態をリセット
        imageView.layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        imageView.layer?.position = CGPoint(x: imageView.bounds.midX, y: imageView.bounds.midY)
        imageView.layer?.setAffineTransform(.identity)
    }
    
    // パン（ドラッグによる移動）処理
    private func pan(by delta: NSPoint) {
        // ズーム中（scale > 1.0）のみパン操作を有効にする
        guard zoomScale > 1.0,
              let layer = imageView.layer else { return }

        // 現在のレイヤー位置を取得
        let current = layer.position
        // ドラッグ差分を加算して新しい位置を計算
        let newPos = CGPoint(x: current.x + delta.x, y: current.y + delta.y)
        // レイヤーの位置を更新
        layer.position = newPos
    }
    
    
    override func viewDidLayout() {
        super.viewDidLayout()

        // ビューがリサイズされたときにズーム位置をリセット
        centerImageIfNeeded()
    }
    
    
    
    private func centerImageIfNeeded() {
        guard let layer = imageView.layer else { return }

        // 現在の拡大状態を取得
        let currentTransform = layer.affineTransform()

        // スケールだけ維持、位置は中央へ戻す
        let currentScaleX = currentTransform.a
        let currentScaleY = currentTransform.d

        let newTransform = CGAffineTransform(scaleX: currentScaleX, y: currentScaleY)
        layer.setAffineTransform(newTransform)

        // 拡大中心をビュー中央へ
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.position = CGPoint(x: imageView.bounds.midX, y: imageView.bounds.midY)
    }
    
    // 画像読み込み時にズーム状態を初期化する
//    private func resetZoom() {
//        // ズーム倍率を 1.0 に戻す
//        zoomScale = 1.0
//        // imageScaling をデフォルトに戻す
//        imageView.imageScaling = .scaleProportionallyUpOrDown
//        // 画像ビューのフレームサイズをルートビューに合わせる
//        imageView.setFrameSize(view.bounds.size)
//    }

    // ダブルクリック検出時の処理
    @objc private func handleDoubleClick(_ sender: NSClickGestureRecognizer) {
        // 画像ビュー内でのクリック位置を取得
        let location = sender.location(in: imageView)
        // ズーム中心をクリック位置に設定
        setZoomCenter(at: location)
        // ズーム倍率を順に切り替える
        cycleZoom()
    }
    
    // ズーム中心を指定ポイントに変更する処理
    private func setZoomCenter(at point: CGPoint) {
        // レイヤーがあることを確認
        guard let layer = imageView.layer else { return }

        // 画像ビューの大きさを取得
        let bounds = imageView.bounds
        // 相対的なアンカーポイントを計算
        let anchorX = point.x / bounds.width
        let anchorY = point.y / bounds.height

        // レイヤーのアンカーポイントを設定
        layer.anchorPoint = CGPoint(x: anchorX, y: anchorY)
        // レイヤーの描画位置を調整
        layer.position = point
    }
 
    // ダブルクリックでズーム倍率を 1.0→2.0→4.0→1.0 とサイクルする
    private func cycleZoom() {
        // 画像とレイヤーがあることを確認
        guard let _ = imageView.image, let layer = imageView.layer else { return }

        // 現在のズーム倍率に応じて次の倍率に切り替え
        switch zoomScale {
        case ..<1.5:
            zoomScale = 2.0
        case ..<3.5:
            zoomScale = 4.0
        default:
            zoomScale = 1.0
            // リセット時は中心に戻す
            layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            layer.position = CGPoint(x: imageView.bounds.midX, y: imageView.bounds.midY)
        }
        // 新しい倍率を適用
        applyTransform(iv: imageView)
    }
    
    // レイヤーにスケーリング変形を適用する共通メソッド
    private func applyTransform(iv: NSImageView) {
        // 現在のズーム倍率を取得
        let scale = zoomScale
        // AffineTransform でスケールを設定
        iv.layer?.setAffineTransform(CGAffineTransform(scaleX: scale, y: scale))
    }
    
    // ホイールやピンチによるズーム処理
    private func zoom(by scaleFactor: CGFloat, at point: CGPoint) {
        // レイヤーがあることを確認
        guard let layer = imageView.layer else { return }

        // 現在倍率に乗算して更新
        zoomScale *= scaleFactor
        // 0.1～10.0 の範囲にクランプ
        zoomScale = min(max(zoomScale, 0.1), 10.0)

        // ズーム起点の相対アンカーポイントを計算
        let bounds = imageView.bounds
        let anchorX = point.x / bounds.width
        let anchorY = point.y / bounds.height
        layer.anchorPoint = CGPoint(x: anchorX, y: anchorY)
        layer.position = point

        // 更新後の倍率を適用
        applyTransform(iv: imageView)
    }

    // ズーム＆パン機能を持つカスタム NSView
    class ZoomableImageViewContainer: NSView {
        // ズームイベントのコールバッククロージャ
        var onZoom: ((CGFloat, CGPoint) -> Void)?
        // パンイベントのコールバッククロージャ
        var onPan: ((NSPoint) -> Void)?

        // ドラッグ中を示すフラグ
        private var isDragging = false
        // ドラッグ開始位置を保持
        private var lastDragLocation: NSPoint?

        // トラックパッドやマウスホイールのスクロール処理
        override func scrollWheel(with event: NSEvent) {
            // command キー押下でズーム、その他は標準スクロール
            if event.modifierFlags.contains(.command) {
                let delta = event.deltaY
                let zoomFactor = delta > 0 ? 1.1 : 0.9
                let location = convert(event.locationInWindow, from: nil)
                onZoom?(zoomFactor, location)
            } else {
                super.scrollWheel(with: event)
            }
        }

        // トラックパッドのピンチジェスチャーによるズーム処理
        override func magnify(with event: NSEvent) {
            let zoomFactor = 1.0 + event.magnification
            let location = convert(event.locationInWindow, from: nil)
            onZoom?(zoomFactor, location)
        }

        // マウス押下イベント処理（パン開始）
        override func mouseDown(with event: NSEvent) {
            isDragging = true
            lastDragLocation = convert(event.locationInWindow, from: nil)
        }

        // マウスドラッグイベント処理（パン実行）
        override func mouseDragged(with event: NSEvent) {
            guard isDragging, let lastLocation = lastDragLocation else { return }
            let currentLocation = convert(event.locationInWindow, from: nil)
            let delta = NSPoint(x: currentLocation.x - lastLocation.x,
                                y: currentLocation.y - lastLocation.y)
            onPan?(delta)
            lastDragLocation = currentLocation
        }

        // マウスリリースイベント処理（パン終了）
        override func mouseUp(with event: NSEvent) {
            isDragging = false
            lastDragLocation = nil
        }

        // ファーストレスポンダーを許可してジェスチャーを受け取る
        override var acceptsFirstResponder: Bool { true }
    }
}
