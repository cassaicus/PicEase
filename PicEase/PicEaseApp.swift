import SwiftUI

/// アプリケーションのエントリーポイント（起点）を定義します。
/// `@main`属性により、この構造体がアプリの起動時に実行されることを示します。
@main
struct PicEaseApp: App {

    // MARK: - Properties

    /// `AppDelegate`をSwiftUIアプリケーションのライフサイクルに組み込むためのプロパティラッパー。
    /// これにより、従来のAppKitのデリゲートメソッド（例：アプリ起動時の処理）を利用できます。
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// 画像ブラウジングの状態（画像リスト、選択インデックス）を管理するデータモデル。
    /// `@StateObject`として宣言され、アプリのライフサイクル全体でインスタンスが維持されます。
    @StateObject private var model: PageControllerWrapper

    /// ブックマーク機能を管理するデータストア。
    /// こちらも`@StateObject`として宣言され、アプリ全体で共有されます。
    @StateObject private var bookmarkStore: BookmarkStore

    /// アプリケーション全体の設定を管理するデータストア。
    @StateObject private var settingsStore = SettingsStore()

    // MARK: - Initialization

    /// アプリの初期化処理。
    /// `body`が評価される前に一度だけ呼び出されます。
    /// ここで、依存関係を持つオブジェクト（`BookmarkStore`が`PageControllerWrapper`に依存）を正しく初期化します。
    init() {
        // `PageControllerWrapper`のインスタンスをまず作成します。
        let initialModel = PageControllerWrapper()
        // 作成したインスタンスを使用して`@StateObject`プロパティを初期化します。
        _model = StateObject(wrappedValue: initialModel)
        // `BookmarkStore`の初期化時に、依存する`model`のインスタンスを渡します。
        _bookmarkStore = StateObject(wrappedValue: BookmarkStore(model: initialModel))
    }

    // MARK: - Body

    /// アプリケーションのUI階層（シーン）を定義します。
    var body: some Scene {
        // メインウィンドウを定義します。
        Window("PicEase", id: "main") {
            // ウィンドウのコンテンツとして`ContentView`を設定します。
            ContentView()
                // `environmentObject`を使用して、`model`をビュー階層全体に供給します。
                // これにより、階層内のどのビューからでも`model`にアクセスできます。
                .environmentObject(model)
                // 同様に`bookmarkStore`もビュー階層に供給します。
                .environmentObject(bookmarkStore)
                // `settingsStore`もビュー階層に供給します。
                .environmentObject(settingsStore)
        }
        // ウィンドウのタイトルバーを非表示にするスタイルを適用します。
        .windowStyle(HiddenTitleBarWindowStyle())
        // アプリケーションのメニューバーにカスタムコマンドを追加します。
        .commands {
            // ファイル関連の標準的なメニュー項目を定義します。
            FileCommands()
            // ブックマーク関連のカスタムメニュー項目を定義します。
            BookmarkCommands(
                store: bookmarkStore,
                model: model
            )
        }

        // 標準的な「設定...」メニュー項目とウィンドウを提供します。
        Settings {
            SettingsView()
        }
    }
}

// MARK: - Notification.Name Extension

/// アプリケーション全体で使われるカスタム通知名を一元管理するための拡張です。
/// `static let`で定義することで、タイプセーフで間違いの少ない通知の送受信が可能になります。
extension Notification.Name {
    /// フォルダ選択パネルを開くための通知。
    static let openFolder = Notification.Name("openFolder")
    /// 画像選択パネルを開くための通知。
    static let openImage = Notification.Name("openImage")
    /// Finderなど外部からファイルが開かれたことを示す通知。
    static let openFromExternal = Notification.Name("openFromExternal")
    /// ブックマークからフォルダを開くための通知。
    static let openFolderFromBookmark = Notification.Name("openFolderFromBookmark")
    /// サムネイルが選択されたことを`NSPageController`に伝えるための通知。
    static let thumbnailSelected = Notification.Name("thumbnailSelected")
    /// メイン画像がクリックされたことを`ContentView`に伝えるための通知。
    static let mainImageClicked = Notification.Name("mainImageClicked")
    /// 現在のビューの強制的な再描画を要求するための通知。
    static let refreshCurrentPage = Notification.Name("refreshCurrentPage")
    /// 画像の端でナビゲーションしようとしたときに画像を揺らすための通知。
    static let shakeImage = Notification.Name("shakeImage")
}
