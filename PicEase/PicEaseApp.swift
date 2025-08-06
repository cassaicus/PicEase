
import SwiftUI

@main
struct PicEaseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // ImageViewerModel をアプリ全体で共有
    @StateObject private var model = PageControllerWrapper()
    // BookmarkStore も同様に共有
    @StateObject private var bookmarkStore: BookmarkStore

    // 初期化時に BookmarkStore に model を渡す
    init() {
        let model = PageControllerWrapper()
        _model = StateObject(wrappedValue: model)
        _bookmarkStore = StateObject(wrappedValue: BookmarkStore(model: model))
    }

    var body: some Scene {
        Window("PicEase", id: "main") {
            ContentView()
                .environmentObject(model)
                .environmentObject(bookmarkStore)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        // Fileブックマーク機能を追加
        .commands {
            // File メニュー定義
            FileCommands()
            //bookmarkメニュー
            BookmarkCommands(
                store: bookmarkStore,
                model: model
            )
        }
    }
}

extension Notification.Name {
    //openFolder
    static let openFolder = Notification.Name("openFolder")
    //AppDelegateからファイルを開く
    static let openFromExternal = Notification.Name("openFromExternal")
    // Bookmarkフォルダーオープンの通知名
    static let openFolderFromBookmark = Notification.Name("openFolderFromBookmark")
    // サムネイル選択の通知名
    static let thumbnailSelected = Notification.Name("thumbnailSelected")
    //メイン画像クリック
    static let mainImageClicked = Notification.Name("mainImageClicked")
    //強制再描写
    //static let forceRebuildLayout = Notification.Name("forceRebuildLayout")

}
