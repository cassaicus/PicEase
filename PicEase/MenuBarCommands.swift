import SwiftUI

/// 設定メニュー（"Setting"）に関連するコマンドを定義します。
struct SettingsCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandMenu("Setting") {
            Button("設定...") {
                openWindow(id: "settings-window")
            }
            .keyboardShortcut(",", modifiers: [.command])

            Divider()

            Button("PicEaseを終了") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("Q", modifiers: [.command])
        }
    }
}


/// ファイルメニュー（"File"）に関連するコマンドを定義します。
struct FileCommands: Commands {
    var body: some Commands {
        CommandMenu("File") {
            Button("Open Image") {
                NotificationCenter.default.post(name: .openImage, object: nil)
            }
            .keyboardShortcut("I", modifiers: [.command])

            Button("Open Folder") {
                NotificationCenter.default.post(name: .openFolder, object: nil)
            }
            .keyboardShortcut("O", modifiers: [.command])
        }
    }
}

/// ブックマークメニュー（"Bookmark"）に関連するコマンドを定義します。
struct BookmarkCommands: Commands {

    // MARK: - Properties

    /// ブックマークデータを管理する`BookmarkStore`のインスタンス。
    /// 親（`PicEaseApp`）から`@ObservedObject`として渡され、UIがストアの変更に追従します。
    @ObservedObject var store: BookmarkStore

    /// 現在の画像情報を管理する`PageControllerWrapper`のインスタンス。
    @ObservedObject var model: PageControllerWrapper

    // MARK: - Body

    var body: some Commands {
        // "Bookmark"というタイトルのメニューグループを作成します。
        CommandMenu("Bookmark") {

            // "Add Bookmark Folder"メニュー項目
            Button("Add Bookmark Folder") {
                // `BookmarkStore`にフォルダ選択パネルを開かせるメソッドを呼び出します。
                store.selectAndAddBookmark()
            }
            
            // "Remove Bookmark"サブメニュー
            Menu("Remove Bookmark") {
                // ブックマークが1つもない場合の表示
                if store.items.isEmpty {
                    Text("No bookmarks").disabled(true) // 選択不可にする
                } else {
                    // 保存されているブックマーク項目をループで表示
                    ForEach(store.items) { bookmark in
                        Button(bookmark.title) {
                            // 対応するブックマークを削除
                            store.removeBookmark(for: bookmark.url)
                        }
                    }
                    // 区切り線
                    Divider()
                    // すべてのブックマークを削除するボタン
                    Button("Remove All") {
                        store.removeAll()
                    }
                }
            }

            // 区切り線
            Divider()

            // 保存されているブックマークをメニュー項目として直接表示
            ForEach(store.items) { bookmark in
                Button(bookmark.title) {
                    // `ImagePageController`に、このブックマークのフォルダを開くよう通知
                   NotificationCenter.default.post(name: .openFolderFromBookmark, object: bookmark.url)
                }
            }
        }
    }
}
