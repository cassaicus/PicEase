import SwiftUI

/// アプリケーションのメインメニュー（"PicEase"）に関連するコマンドを定義します。
struct AppCommands: Commands {
    // openWindow環境アクションを取得して、プログラムでウィンドウを開くために使用します。
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        // "PicEase"というタイトルのトップレベルメニューを作成します。
        CommandMenu("PicEase") {
            // "設定"メニュー項目
            Button("設定...") {
                // "settings-window"というIDを持つウィンドウを開きます。
                // このIDはPicEaseAppで定義されます。
                openWindow(id: "settings-window")
            }
            // 標準的なキーボードショートカット Command+, を設定します。
            .keyboardShortcut(",", modifiers: [.command])

            // メニュー項目間に区切り線を追加します。
            Divider()

            // "Quit"メニュー項目
            Button("PicEaseを終了") {
                // アプリケーションを終了させます。
                NSApp.terminate(nil)
            }
            // 標準的なキーボードショートカット Command+Q を設定します。
            .keyboardShortcut("Q", modifiers: [.command])
        }
    }
}


/// ファイルメニュー（"File"）に関連するコマンドを定義します。
struct FileCommands: Commands {
    var body: some Commands {
        // "File"というタイトルのメニューグループを作成します。
        CommandMenu("File") {

            // "Open Image"メニュー項目
            Button("Open Image") {
                // `ImagePageController`に画像選択パネルを開くよう通知します。
                NotificationCenter.default.post(name: .openImage, object: nil)
            }
            // キーボードショートカットとして Command+I を設定します。
            .keyboardShortcut("I", modifiers: [.command])

            // "Open Folder"メニュー項目
            Button("Open Folder") {
                // `ImagePageController`にフォルダ選択パネルを開くよう通知します。
                NotificationCenter.default.post(name: .openFolder, object: nil)
            }
            // キーボードショートカットとして Command+O を設定します。
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
