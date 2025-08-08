import SwiftUI

/// アプリケーションのメインウィンドウのコンテンツを定義する、中心的なSwiftUIビューです。
struct ContentView: View {

    // MARK: - State Properties

    /// `NSPageController`のデータソースと状態を管理する共有オブジェクト。
    /// `@StateObject`としてここでインスタンス化され、このビューとその子ビューのライフサイクルにわたって維持されます。
    @StateObject private var controller = PageControllerWrapper()

    /// ウィンドウサイズが変更されたときに再描画を遅延実行するためのタスク。
    @State private var resizeTask: DispatchWorkItem?
    
    @State private var isHintIconVisible: Bool = false

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
