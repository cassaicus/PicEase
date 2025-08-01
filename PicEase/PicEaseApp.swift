import SwiftUI

@main
struct PicEaseApp: App {
    var body: some Scene {
        Window("PicEase", id: "mainWindow") {
            ContentView()
                .edgesIgnoringSafeArea(.all) // フル領域使用
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            CommandMenu("ブックマーク") {
                Button("フォルダーを開く") {
                    NotificationCenter.default.post(name: .openFolder, object: nil)
                }
                .keyboardShortcut("O", modifiers: [.command])
            }
        }
    }
}

extension Notification.Name {
    static let openFolder = Notification.Name("openFolder")
}
