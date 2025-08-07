import SwiftUI
import Combine

/// ブックマークされたフォルダを管理するためのデータモデルクラス。
/// フォルダのURLを永続的に保存し、UIに表示するためのデータを提供します。
class BookmarkStore: ObservableObject {

    // MARK: - Nested Struct

    /// 1つのブックマークデータを表現する構造体。
    /// - `Identifiable`: `ForEach`で一意に識別するために必要。
    /// - `Codable`: JSONへのエンコード/デコードのために必要。
    /// - `Equatable`: 配列内での比較のために必要。
    struct Bookmark: Identifiable, Codable, Equatable {
        var id = UUID()         // 一意なID
        var title: String        // 表示用のタイトル（通常はフォルダ名）
        var url: URL             // 実際のフォルダのURL
    }

    // MARK: - Published Properties

    /// UIに表示するためのブックマーク項目の配列。
    /// `@Published`により、この配列の変更がUIに自動的に反映されます。
    @Published var items: [Bookmark] = []

    // MARK: - Private Properties

    /// `@AppStorage`を使い、ブックマークされたフォルダのパスの配列をJSON文字列としてUserDefaultsに永続化します。
    /// "bookmarkedFolders"はUserDefaults内で使用されるキーです。
    @AppStorage("bookmarkedFolders") private var bookmarkedFoldersData: String = "[]"

    /// 現在の画像情報を保持するモデルへの弱参照。循環参照を防ぐために`weak`を使用します。
    private weak var model: PageControllerWrapper?

    // MARK: - Initialization

    /// `BookmarkStore`を初期化します。
    /// - Parameter model: アプリケーションの共有データモデルへの参照。
    init(model: PageControllerWrapper) {
        self.model = model
        // 起動時に保存されているブックマークを読み込みます。
        loadBookmarks()
    }

    // MARK: - Computed Properties

    /// `bookmarkedFoldersData`（JSON文字列）と実際の`[String]`配列との間の変換を行う計算型プロパティ。
    private var bookmarkedPaths: [String] {
        get {
            // JSON文字列をUTF-8データに変換
            guard let data = bookmarkedFoldersData.data(using: .utf8) else { return [] }
            // JSONデコーダを使って、データから`[String]`配列にデコード
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            // `[String]`配列をJSONデータにエンコード
            let data = try? JSONEncoder().encode(newValue)
            // エンコードしたデータをUTF-8文字列に変換して`@AppStorage`プロパティに保存
            bookmarkedFoldersData = data.flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
            // データが変更されたので、UI表示用の`items`も更新
            loadBookmarks()
        }
    }

    // MARK: - Public Methods

    /// `bookmarkedPaths`（パスの文字列配列）から、UI表示用の`items`（`Bookmark`構造体の配列）を生成します。
    func loadBookmarks() {
        items = bookmarkedPaths.compactMap { path in
            let url = URL(fileURLWithPath: path)
            // パスからURLを生成し、`Bookmark`オブジェクトを作成
            return Bookmark(title: url.lastPathComponent, url: url)
        }
    }

    /// フォルダ選択パネルを表示し、選択されたフォルダをブックマークに追加します。
    func selectAndAddBookmark() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false       // ファイル選択は不可
        panel.canChooseDirectories = true  // フォルダ選択を許可
        panel.allowsMultipleSelection = false // 複数選択は不可
        panel.prompt = "Select"            // ボタンのラベルを"Select"に

        // ユーザーがパネルでフォルダを選択して "Select" を押した場合
        if panel.runModal() == .OK, let folderURL = panel.url {
            addBookmark(from: folderURL)
        }
    }

    /// 指定されたURLのフォルダをブックマークに追加します。
    /// - Parameter folderURL: ブックマークに追加するフォルダのURL。
    func addBookmark(from folderURL: URL) {
        let path = folderURL.path
        // すでにブックマークに存在するかどうかを確認
        guard !bookmarkedPaths.contains(path) else { return }
        // 存在しない場合のみ、パスを配列に追加
        bookmarkedPaths.append(path)
    }

    /// 指定されたURLのブックマークを削除します。
    /// - Parameter folderURL: 削除するブックマークのフォルダURL。
    func removeBookmark(for folderURL: URL) {
        let path = folderURL.path
        // 指定されたパスと一致しないものだけを残す（＝一致するものを削除）
        bookmarkedPaths.removeAll { $0 == path }
    }

    /// すべてのブックマークを削除します。
    func removeAll() {
        bookmarkedPaths = []
    }
}
