import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        // Finder などから画像ファイルを開いたときにここに来る
        NotificationCenter.default.post(name: .openFromExternal, object: urls)
    }
}
