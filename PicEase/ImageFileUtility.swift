import Foundation

// 画像ファイルの処理に関連するユーティリティ関数を提供する構造体
struct ImageFileUtility {

    // アプリケーションでサポートする画像ファイルの拡張子を小文字の配列で定義
    private static let supportedExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "webp"]

    /// 指定されたURLがサポート対象の画像ファイルであるかを確認します。
    /// - Parameter url: 確認対象のファイルURL。
    /// - Returns: サポート対象の拡張子を持つ画像ファイルであれば `true`、そうでなければ `false`。
    static func isSupportedImage(url: URL) -> Bool {
        // URLから拡張子を取得し、小文字に変換して、定義した拡張子リストに含まれているかチェック
        return supportedExtensions.contains(url.pathExtension.lowercased())
    }

    /// URLの配列から、サポート対象の画像ファイルのみをフィルタリングし、ファイル名でソートして返します。
    /// - Parameter urls: フィルタリングとソートを行うURLの配列。
    /// - Returns: フィルタリングおよびソート済みの画像URL配列。
    static func filterAndSortImageURLs(from urls: [URL]) -> [URL] {
        return urls
            // 配列内の各URLがサポート対象の画像であるかをチェックしてフィルタリング
            .filter { isSupportedImage(url: $0) }
            // ファイル名でロケールを考慮した自然順ソートを実行
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }
}
