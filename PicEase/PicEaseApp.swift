
import SwiftUI

@main
struct PicEaseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // ImageViewerModel をアプリ全体で共有
    @StateObject private var model = PageControllerWrapper()
    // BookmarkStore も同様に共有
    @StateObject private var bookmarkStore: BookmarkStore
    //@StateObject private var imagePageControllerWrapper: ImagePageControllerWrapper
    
    
    // 初期化時に BookmarkStore に model を渡す
    init() {
        let model = PageControllerWrapper()
        _model = StateObject(wrappedValue: model)
        _bookmarkStore = StateObject(wrappedValue: BookmarkStore(model: model))
       // _imagePageControllerWrapper = StateObject(wrappedValue: ImagePageControllerWrapper(model: model))

    }

    var body: some Scene {
        Window("PicEase", id: "main") {
            ContentView()
                .environmentObject(model)
                .environmentObject(bookmarkStore)
                //.environmentObject(imagePageControllerWrapper)

        }
        .windowStyle(HiddenTitleBarWindowStyle())

        // ブックマーク機能を追加
        .commands {
            BookmarkCommands(
                store: bookmarkStore,
                model: model
                //,imagePageController: imagePageControllerWrapper
            )
        }
    }
}

extension Notification.Name {
    // サムネイル選択の通知名
    static let thumbnailSelected = Notification.Name("thumbnailSelected")
    //AppDelegateからファイルを開く
    static let openFromExternal = Notification.Name("openFromExternal")
    // Bookmarkフォルダーオープンの通知名
    static let openFolderFromBookmark = Notification.Name("openFolderFromBookmark")

}
