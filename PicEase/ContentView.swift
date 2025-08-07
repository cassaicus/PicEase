import SwiftUI

/// アプリケーションのメインウィンドウのコンテンツを定義する、中心的なSwiftUIビューです。
struct ContentView: View {

    // MARK: - State Properties

    /// `NSPageController`のデータソースと状態を管理する共有オブジェクト。
    /// `@StateObject`としてここでインスタンス化され、このビューとその子ビューのライフサイクルにわたって維持されます。
    @StateObject private var controller = PageControllerWrapper()

    /// サムネイルバーとコントロールバーの表示状態を管理するフラグ。
    @State private var isThumbnailVisible = true

    /// マウスホバーによる表示/非表示の切り替えが短時間に連続して発生するのを防ぐためのフラグ。
    @State private var canToggleThumbnail = true

    /// サムネイルバーを非表示にするための遅延実行タスク。
    /// マウスが領域外に移動した際にセットされ、一定時間後に実行されます。
    @State private var hideTask: DispatchWorkItem?

    /// ウィンドウサイズが変更されたときに再描画を遅延実行するためのタスク。
    @State private var resizeTask: DispatchWorkItem?
    
    // MARK: - Body

    var body: some View {
        // `GeometryReader` を使用して、親ビュー（この場合はウィンドウ全体）のサイズと座標系を取得します。
        GeometryReader { geometry in
            // 垂直方向にビューを配置するVStack。`spacing: 0`でビュー間の隙間をなくします。
            VStack(spacing: 0) {
                // ZStackを使用して、画像ビューと他のUI要素（マウストラッキング、オーバーレイ）を重ねて表示します。
                ZStack {
                    // AppKitの`NSPageController`をSwiftUIで表示するためのラッパービュー。
                    PageControllerRepresentable(controller: controller)
                        // 安全領域（ノッチなど）を無視して全画面に表示。
                        .edgesIgnoringSafeArea(.all)
                        // `.mainImageClicked`通知を受信したときの処理。
                        .onReceive(NotificationCenter.default.publisher(for: .mainImageClicked)) { _ in
                            // アニメーション付きでサムネイルバーを非表示にする。
                            withAnimation {
                                // もしサムネイルが表示されていたら、1秒後に再描画を要求。
                                // これは、サムネイルバーが消えた後に画像の表示が崩れる問題への対策。
                                if isThumbnailVisible {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        NotificationCenter.default.post(name: .refreshCurrentPage, object: nil)
                                    }
                                }
                                isThumbnailVisible = false
                            }
                        }
                    
                    // マウスカーソルの位置を追跡するための透明なオーバーレイビュー。
                    MouseTrackingView { location in
                        handleMouseMovement(at: location)
                    }
                    
                    // 表示する画像がない場合に、「Open Folder」ボタンのオーバーレイを表示。
                    if controller.imagePaths.isEmpty {
                        OpenFolderOverlayView()
                    }
                }
                
                // サムネイルバーとコントロールバーの表示/非表示を切り替え。
                if isThumbnailVisible {
                    // 垂直方向にコントロールバーとサムネイルビューを配置。
                    VStack(spacing: 0) {
                        // ナビゲーションコントロールバー
                        ControlBarView(controller: controller, fitImageAction: fitImageToWindow)
                        
                        // サムネイルのスクロールビュー
                        ThumbnailScrollView(
                            imageURLs: controller.imagePaths,
                            currentIndex: $controller.selectedIndex,
                            isThumbnailVisible: $isThumbnailVisible
                        )
                        .frame(height: 100) // 高さを100ポイントに固定
                        .background(Color.black.opacity(0.8)) // 半透明の黒い背景
                        // 下からスライドイン/アウトするアニメーション効果。
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            // ウィンドウのサイズ変更を監視します。
            .onChange(of: geometry.size) {
                // ウィンドウリサイズが頻繁に発生するため、`DispatchWorkItem`で処理を遅延させ、最後の変更後にのみ実行（デバウンス）。
                resizeTask?.cancel() // 以前のタスクがあればキャンセル

                let task = DispatchWorkItem {
                    // `NSPageController`に現在のページを再描画するよう通知
                    NotificationCenter.default.post(name: .refreshCurrentPage, object: nil)
                }
                resizeTask = task

                // 0.35秒の遅延後にタスクを実行
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: task)
            }
        }
    }
    
    // MARK: - UI Logic Methods
    
    /// マウスカーソルの動きを処理し、サムネイルバーの表示/非表示を制御します。
    /// - Parameter location: マウスカーソルの現在位置。
    private func handleMouseMovement(at location: CGPoint) {
        // 短時間の連続トグルを防ぐ
        guard canToggleThumbnail else { return }
        canToggleThumbnail = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { // 0.2秒のクールダウン
            canToggleThumbnail = true
        }

        // マウスカーソルが画面上部から150ポイント以内の領域にあるかチェック
        let threshold: CGFloat = 150
        if location.y <= threshold {
            // 領域内にある場合：
            // アニメーション付きでサムネイルバーを表示
            withAnimation {
                isThumbnailVisible = true
            }
            // 既存の非表示タスクがあればキャンセル（非表示にさせない）
            hideTask?.cancel()
        } else {
            // 領域外にある場合：
            // 新しい非表示タスクを作成
            let task = DispatchWorkItem {
                withAnimation {
                    isThumbnailVisible = false
                }
            }
            hideTask?.cancel() // 以前のタスクをキャンセル
            hideTask = task
            // マウスが領域外に出てから2秒後にタスクを実行
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: task)
        }
    }
    
    /// 現在表示されている画像をウィンドウサイズにフィットさせます。
    func fitImageToWindow() {
        // 現在のメインウィンドウと表示中の画像を取得
        guard let window = NSApp.mainWindow,
              controller.imagePaths.indices.contains(controller.selectedIndex),
              let image = NSImage(contentsOf: controller.imagePaths[controller.selectedIndex])
        else { return }

        let imageSize = image.size
        // ウィンドウが現在表示されているスクリーンの可視領域（メニューバーやDockを除く）を取得
        guard let screenVisibleFrame = window.screen?.visibleFrame else { return }

        // 画像を可視領域に収めるためのスケーリング比率を計算
        let scale = min(screenVisibleFrame.width / imageSize.width,
                        screenVisibleFrame.height / imageSize.height)

        // 新しいウィンドウサイズを計算
        let newWidth = imageSize.width * scale
        let newHeight = imageSize.height * scale

        // 新しいウィンドウの原点（左下の座標）を計算
        // X座標：現在のウィンドウの中心が、新しいサイズの中心になるように設定
        let currentFrame = window.frame
        let newX = currentFrame.origin.x + (currentFrame.width - newWidth) / 2
        // Y座標：可視領域の下端に合わせる
        let newY = screenVisibleFrame.minY

        // 新しいフレーム（位置とサイズ）を作成
        let newFrame = NSRect(x: newX, y: newY, width: newWidth, height: newHeight)

        // ウィンドウのフレームをアニメーション付きで更新
        window.setFrame(newFrame, display: true, animate: true)
    }
    
    // MARK: - Child Views

    /// 画像が読み込まれていないときに表示されるオーバーレイビュー。
    struct OpenFolderOverlayView: View {
        var body: some View {
            ZStack {
                // 半透明の黒い背景
                Color.black.opacity(0.8)

                // 「フォルダを開く」ボタン
                Button(action: {
                    // `.openFolder`通知を送信して、`ImagePageController`にフォルダ選択パネルを開かせる
                    NotificationCenter.default.post(name: .openFolder, object: nil)
                }) {
                    Text("Open Folder")
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle()) // 標準のボタンスタイルを無効化
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
        }
    }

    /// マウスカーソルの位置を継続的に追跡するための`NSViewRepresentable`ラッパー。
    struct MouseTrackingView: NSViewRepresentable {
        var onMove: (CGPoint) -> Void // マウスが移動したときに呼び出されるコールバック

        func makeNSView(context: Context) -> NSView {
            let view = TrackingNSView()
            view.onMove = onMove
            return view
        }

        func updateNSView(_ nsView: NSView, context: Context) {}

        /// マウストラッキング機能を実装したカスタム`NSView`。
        class TrackingNSView: NSView {
            var onMove: ((CGPoint) -> Void)?

            // `updateTrackingAreas`は、ビューのサイズや位置が変わったときに呼び出されるため、
            // ここでトラッキングエリアを再設定するのが最も確実です。
            override func updateTrackingAreas() {
                super.updateTrackingAreas()
                // 既存のトラッキングエリアをすべて削除して重複を防ぐ
                trackingAreas.forEach(removeTrackingArea)

                // 新しいトラッキングエリアを作成
                let area = NSTrackingArea(
                    rect: bounds, // ビュー全体を追跡範囲とする
                    options: [
                        .mouseMoved,         // マウス移動イベントを補足
                        .activeInKeyWindow,  // アプリがアクティブなときのみ追跡
                        .inVisibleRect       // ビューの可視部分のみ追跡
                    ],
                    owner: self,
                    userInfo: nil
                )
                addTrackingArea(area)
            }

            // マウスが移動したときに呼び出される
            override func mouseMoved(with event: NSEvent) {
                // マウスのウィンドウ座標をビューのローカル座標に変換してコールバックを呼び出し
                onMove?(convert(event.locationInWindow, from: nil))
            }
            
            // このビューがクリックイベントを補足しないように`nil`を返す（イベントを下のビューに透過させる）。
            override func hitTest(_ point: NSPoint) -> NSView? {
                return nil
            }
        }
    }
}
