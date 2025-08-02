// SwiftUI フレームワークをインポートして View の構築を可能にする
import SwiftUI

// メインのコンテンツビューを定義し、ページ切り替えとサムネイル表示を管理
struct ContentView: View {
    // ページ制御用のラッパーを StateObject で保持
    @StateObject private var controller = PageControllerWrapper()
    // サムネイル表示の可視/非可視を管理する状態フラグ
    @State private var isThumbnailVisible = true
    // PageControllerRepresentable の Coordinator を事前生成し、Responder 再設定に利用
    private let pageControllerCoordinator = PageControllerRepresentable.Coordinator()
    // ビューのレイアウトを定義する本体
    var body: some View {
        // 縦方向に積むスタック、アイテム間隔を 0 に設定
        VStack(spacing: 0) {
            // 重ね合わせスタックでページ表示とマウストラッキングを重ねる
            ZStack {
                // NSPageController を SwiftUI に組み込むカスタムビュー
                PageControllerRepresentable(controller: controller, coordinator: pageControllerCoordinator)
                    // SafeArea を無視して全画面表示にする
                    .edgesIgnoringSafeArea(.all)

                // マウス位置を追跡し、位置に応じてサムネイル表示を制御するビュー
                MouseTrackingView { location in
                    // マウスの y 座標しきい値を設定
                    let threshold: CGFloat = 150
                    // マウスが上部しきい値以内ならサムネイルを表示
                    if location.y <= threshold {
                        withAnimation {
                            isThumbnailVisible = true
                        }
                    } else {
                        // しきい値超えたら 2 秒後に非表示に
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                isThumbnailVisible = false
                            }
                        }
                    }
                }
            }
            // isThumbnailVisible が true のときのみサムネイルリストを表示
            if isThumbnailVisible {
                // 横スクロールサムネイルビューを生成し、バインドで選択インデックスを共有
                ThumbnailScrollView(imageURLs: controller.imagePaths, currentIndex: $controller.selectedIndex)
                    // 高さを 100 に固定
                    .frame(height: 100)
                    // 背景を半透明の黒で覆う
                    .background(Color.black.opacity(0.8))
                    // 表示/非表示アニメーションに移動とフェードを組み合わせる
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}


// AppKit の NSView をラップしてマウス移動を検出するビューを定義
struct MouseTrackingView: NSViewRepresentable {
    // マウス移動時のコールバッククロージャ
    var onMove: (CGPoint) -> Void
    // NSView を生成し、トラッキング用サブクラスを返す
    func makeNSView(context: Context) -> NSView {
        let trackingView = TrackingNSView()
        trackingView.onMove = onMove
        return trackingView
    }
    // 値更新時のビュー更新は不要なので空実装
    func updateNSView(_ nsView: NSView, context: Context) {}
    // マウス移動を監視する NSView サブクラスを内部定義
    class TrackingNSView: NSView {
        // 移動イベント発生時に呼び出すクロージャ
        var onMove: ((CGPoint) -> Void)?
        // トラッキングエリアを再設定してマウス移動を常に監視
        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            // 既存のトラッキングエリアを一旦削除
            trackingAreas.forEach(removeTrackingArea)
            // ビュー全体を対象とするトラッキングエリアを追加
            let area = NSTrackingArea(rect: bounds,
                                      options: [.mouseMoved, .activeInKeyWindow, .inVisibleRect],
                                      owner: self, userInfo: nil)
            addTrackingArea(area)
        }
        // マウスが動いたときに onMove クロージャを呼び出し
        override func mouseMoved(with event: NSEvent) {
            onMove?(convert(event.locationInWindow, from: nil))
        }
        // hitTest をオーバーライドし、子ビューへのイベント伝播を阻害しない（常に nil を返す）
        override func hitTest(_ point: NSPoint) -> NSView? {
            return nil
        }
    }
}
