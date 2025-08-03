import SwiftUI

@main
struct PicEaseApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // アプリのエントリーポイント
    var body: some Scene {
        // メインウィンドウを作成
        Window("PicEase", id: "main") {
            ContentView() // メインUI
                .edgesIgnoringSafeArea(.all) // 画面端まで表示
        }
        .windowStyle(HiddenTitleBarWindowStyle()) // タイトルバーを隠すスタイル
        .commands {
            // カスタムメニュー追加（ブックマーク）
            CommandMenu("ブックマーク") {
                // フォルダーを開くメニュー項目
                Button("フォルダーを開く") {
                    NotificationCenter.default.post(name: .openFolder, object: nil) // 通知送信
                }
                .keyboardShortcut("O", modifiers: [.command]) // ショートカット: ⌘O
            }
        }
    }
}

extension Notification.Name {
    // フォルダーオープンの通知名
    static let openFolder = Notification.Name("openFolder")
    // サムネイル選択の通知名
    static let thumbnailSelected = Notification.Name("thumbnailSelected")
    //AppDelegate
    static let openFromExternal = Notification.Name("openFromExternal")
}
