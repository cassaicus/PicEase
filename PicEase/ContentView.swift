import SwiftUI

/// アプリケーションのメインウィンドウのコンテンツを定義する、中心的なSwiftUIビューです。
struct ContentView: View {

    // MARK: - State Properties

    /// `NSPageController`のデータソースと状態を管理する共有オブジェクト。
    /// `@StateObject`としてここでインスタンス化され、このビューとその子ビューのライフサイクルにわたって維持されます。
    @StateObject private var controller = PageControllerWrapper()

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
                        .onReceive(NotificationCenter.default.publisher(for: .showThumbnail)) { _ in
                            withAnimation {
                                controller.isThumbnailVisible = true
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: .hideThumbnail)) { _ in
                            withAnimation {
                                controller.isThumbnailVisible = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                NotificationCenter.default.post(name: .refreshCurrentPage, object: nil)
                            }
                        }
                    
                    // 表示する画像がない場合に、「Open Folder」ボタンのオーバーレイを表示。
                    if controller.imagePaths.isEmpty {
                        OpenFolderOverlayView()
                    }
                }
                
                // サムネイルバーとコントロールバーの表示/非表示を切り替え。
                if controller.isThumbnailVisible {
                    // 垂直方向にコントロールバーとサムネイルビューを配置。
                    VStack(spacing: 0) {
                        // ナビゲーションコントロールバー
                        ControlBarView(controller: controller, fitImageAction: fitImageToWindow)
                        
                        // サムネイルのスクロールビュー
                        ThumbnailScrollView(
                            imageURLs: controller.imagePaths,
                            currentIndex: $controller.selectedIndex,
                            isThumbnailVisible: $controller.isThumbnailVisible
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
}
