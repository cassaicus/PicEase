// SwiftUI フレームワークをインポートして View を利用可能にする
import SwiftUI

// AppDelegate クラスを定義し、SwiftUI と AppKit の統合ポイントとする
class AppDelegate: NSObject, NSApplicationDelegate {
    // アプリケーションのメインウィンドウを保持するプロパティ
    var window: NSWindow?

    // アプリケーション起動完了後に呼ばれるライフサイクルメソッド
    func applicationDidFinishLaunching(_ notification: Notification) {
        // SwiftUI のルートビューを生成
        let contentView = ContentView()
        // NSWindow を初期化し、サイズ・スタイルを指定
        let window = NSWindow(
            contentRect: NSMakeRect(0, 0, 800, 600),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // ウィンドウタイトルを非表示に設定
        window.titleVisibility = .hidden
        // タイトルバーを透明にして背景と一体化させる
        window.titlebarAppearsTransparent = true
        // 背景領域をドラッグ可能にし、ウィンドウ移動を有効化
        window.isMovableByWindowBackground = true
        // SwiftUI の View を NSWindow のコンテンツとしてホスティング
        window.contentView = NSHostingView(rootView: contentView)
        // ウィンドウを前面に表示し、キーボードフォーカスを与える
        window.makeKeyAndOrderFront(nil)
        // 作成したウィンドウをプロパティに保持
        self.window = window
    }
}
