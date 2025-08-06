import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        // Finder などから画像ファイルを開いたときにここに来る
        
        
        NotificationCenter.default.post(name: .openFromExternal, object: urls)

//        for url in urls {
//            if ["jpg", "jpeg", "png", "gif", "bmp", "webp"].contains(url.pathExtension.lowercased()) {
//                NotificationCenter.default.post(name: .openFromExternal, object: url)
//            }
//        }
    }
}
