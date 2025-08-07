import SwiftUI

/// アプリケーションのデリゲートクラスです。
/// SwiftUIのライフサイクルでは直接扱いにくい、古くからのAppKitの機能やイベントを処理するために使用します。
class AppDelegate: NSObject, NSApplicationDelegate {

    /// アプリケーションがFinderなど、外部からファイルまたはURLを開くように要求されたときに呼び出されるデリゲートメソッドです。
    /// - Parameters:
    ///   - application: NSApplicationのインスタンス。
    ///   - urls: 開くように要求されたファイルやデータのURLの配列。
    func application(_ application: NSApplication, open urls: [URL]) {
        // このメソッドが受け取ったURLの配列を、アプリケーションの他の部分（この場合はImagePageController）に
        // 通知するために、NotificationCenterを使用してカスタム通知を送信します。
        // `object`としてURL配列を渡すことで、受信側でどのファイルが開かれたかを知ることができます。
        NotificationCenter.default.post(name: .openFromExternal, object: urls)
    }
}
