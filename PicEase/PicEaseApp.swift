import SwiftUI

@main
struct PicEaseApp: App {
    var body: some Scene {
        Window("Image Viewer", id: "main") {
            ContentView()
                .edgesIgnoringSafeArea(.all)
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
    static let thumbnailSelected = Notification.Name("thumbnailSelected")
}
