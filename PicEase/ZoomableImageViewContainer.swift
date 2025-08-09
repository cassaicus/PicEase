import AppKit

/// スクロール方向を示すための列挙型。
enum ScrollDirection {
    case forward
    case backward
}

/// ズームやパン（ドラッグによる移動）操作をハンドリングするためのカスタムNSViewです。
/// このビューは、マウスやトラックパッドのイベントを検知し、
/// 対応するクロージャ（`onZoom`, `onPan`）を呼び出すことで、親のビューコントローラに操作を通知します。
class ZoomableImageViewContainer: NSView {

    // MARK: - Callbacks

    /// ズーム操作が行われたときに呼び出されるクロージャ。
    /// - Parameters:
    ///   - scaleFactor: 拡大率の変化量（例: 1.1で10%拡大）。
    ///   - location: ズーム操作の中心点の座標。
    var onZoom: ((_ scaleFactor: CGFloat, _ location: CGPoint) -> Void)?

    /// パン操作（ドラッグ）が行われたときに呼び出されるクロージャ。
    /// - Parameter delta: 前回の位置からの移動量（x, y）。
    var onPan: ((_ delta: NSPoint) -> Void)?

    /// スクロールによるナビゲーション操作が行われたときに呼び出されるクロージャ。
    var onScrollNavigate: ((_ direction: ScrollDirection) -> Void)?

    // MARK: - Private Properties

    /// 現在、ビューがドラッグ中であるかを示すフラグ。
    private var isDragging = false

    /// ドラッグ操作中の、前回のマウスカーソル位置。
    /// `mouseDragged`イベントで移動量を計算するために使用します。
    private var lastDragLocation: NSPoint?

    // MARK: - Event Handling

    /// マウスホイールのスクロールイベントを処理します。
    /// `Command`キーが押されている場合はズーム操作として扱い、`onZoom`クロージャを呼び出します。
    /// それ以外の場合は、ナビゲーション操作として扱い、`onScrollNavigate`クロージャを呼び出します。
    /// - Parameter event: スクロールイベントに関する情報。
    override func scrollWheel(with event: NSEvent) {
        // Commandキーが押されているかチェック
        if event.modifierFlags.contains(.command) {
            // スクロールのY方向の移動量を取得
            let delta = event.deltaY
            // 移動量に応じて拡大・縮小率を決定（上スクロールで拡大、下で縮小）
            let zoomFactor = delta > 0 ? 1.1 : 0.9
            // イベントが発生したウィンドウ内の座標を取得
            let location = convert(event.locationInWindow, from: nil)
            // ズーム処理をコールバックで通知
            onZoom?(zoomFactor, location)
        } else {
            // 通常のスクロールはナビゲーションとして扱う
            if event.deltaY > 0 {
                onScrollNavigate?(.backward) // 上スクロール/左スワイプ
            } else if event.deltaY < 0 {
                onScrollNavigate?(.forward) // 下スクロール/右スワイプ
            }
        }
    }

    /// トラックパッドのピンチ操作（拡大・縮小）を処理します。
    /// `onZoom`クロージャを呼び出して、ズーム操作を通知します。
    /// - Parameter event: 拡大・縮小イベントに関する情報。
    override func magnify(with event: NSEvent) {
        // ピンチ操作による拡大率（magnification）に1.0を足して、絶対的な倍率に変換
        let zoomFactor = 1.0 + event.magnification
        // イベントが発生したウィンドウ内の座標を取得
        let location = convert(event.locationInWindow, from: nil)
        // ズーム処理をコールバックで通知
        onZoom?(zoomFactor, location)
    }

    /// マウスの左ボタンが押されたときのイベントを処理します。
    /// ドラッグ状態を開始し、現在のカーソル位置を保存します。
    /// - Parameter event: マウスダウンイベントに関する情報。
    override func mouseDown(with event: NSEvent) {
        // ドラッグ中フラグを立てる
        isDragging = true
        // 現在のマウス位置を保存
        lastDragLocation = convert(event.locationInWindow, from: nil)
    }

    /// マウスがドラッグされたときのイベントを処理します。
    /// ドラッグ中であれば、前回の位置からの移動量を計算し、`onPan`クロージャを呼び出します。
    /// - Parameter event: マウスドラッグイベントに関する情報。
    override func mouseDragged(with event: NSEvent) {
        // ドラッグ中で、かつ前回の位置が記録されていることを確認
        guard isDragging, let lastLocation = lastDragLocation else { return }
        // 現在のマウス位置を取得
        let currentLocation = convert(event.locationInWindow, from: nil)
        // 前回位置との差分（移動量）を計算
        let delta = NSPoint(x: currentLocation.x - lastLocation.x,
                            y: currentLocation.y - lastLocation.y)
        // パン操作をコールバックで通知
        onPan?(delta)
        // 現在位置を次回の計算のために保存
        lastDragLocation = currentLocation
    }

    /// マウスの左ボタンが離されたときのイベントを処理します。
    /// ドラッグ状態を終了します。
    /// - Parameter event: マウスアップイベントに関する情報。
    override func mouseUp(with event: NSEvent) {
        // ドラッグ中フラグを解除
        isDragging = false
        // 前回の位置情報をクリア
        lastDragLocation = nil
    }

    // MARK: - First Responder

    /// このビューがキーボードイベントを受け付けることができる（ファーストレスポンダーになれる）かを示します。
    /// `true`を返すことで、キーイベントの受信が可能になります。
    override var acceptsFirstResponder: Bool { true }
}
