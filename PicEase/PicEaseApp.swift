import SwiftUI

@main
struct PicEaseApp: App {
    // アプリのエントリーポイント
    var body: some Scene {
        // メインウィンドウを作成
        Window("Image Viewer", id: "main") {
            // メインUI
            ContentView()
            // 画面端まで表示
                .edgesIgnoringSafeArea(.all)
        }
        // タイトルバーを隠すスタイル
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            // カスタムメニュー追加（ブックマーク）
            CommandMenu("ブックマーク") {
                // フォルダーを開くメニュー項目
                Button("フォルダーを開く") {
                    // 通知送信
                    NotificationCenter.default.post(name: .openFolder, object: nil)
                }
                // ショートカット: ⌘O
                .keyboardShortcut("O", modifiers: [.command])
            }
        }
    }
}

extension Notification.Name {
    // フォルダーオープンの通知名
    static let openFolder = Notification.Name("openFolder")
    // サムネイル選択の通知名
    static let thumbnailSelected = Notification.Name("thumbnailSelected")
}
