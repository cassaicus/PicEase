// SwiftUIフレームワークをインポートし、ビュー構築に必要な型を利用可能にする
import SwiftUI
// Foundationフレームワークをインポートし、URLや範囲演算子などの基本機能を利用可能にする
import Foundation

// ObservableObjectを継承し、ページコントローラー用のデータ管理を行うクラスを定義
class PageControllerWrapper: ObservableObject {
    // 画像ファイルのURLリストを公開し、変更時にdidSetでプリロードを実行
    @Published var imagePaths: [URL] = [] {
        didSet {
            // imagePathsが更新されたら、現在選択中の前後画像を事前読み込み
            preloadImages(around: selectedIndex)
        }
    }

    // 現在選択中の画像インデックスを公開し、変更時にプリロードを実行
    @Published var selectedIndex: Int = 0 {
        didSet {
            // selectedIndexが更新されたら、前後の画像をキャッシュに読み込む
            preloadImages(around: selectedIndex)
        }
    }

    // 外部から画像URLリストをセットし、選択インデックスを0にリセットするメソッド
    func setImages(_ urls: [URL]) {
        // プロパティに新しいURL配列を代入
        imagePaths = urls
        // ビューを先頭表示にリセット
        selectedIndex = 0
    }

    // 指定インデックスの前後2枚ずつをキャッシュにプリロードするプライベートメソッド
    private func preloadImages(around index: Int) {
        // (index-2)から(index+2)までの範囲を定義
        let range = (index - 2)...(index + 2)
        // 範囲内の各インデックスをループ処理
        for i in range {
            // インデックスが配列の有効範囲内でなければスキップ
            guard imagePaths.indices.contains(i) else { continue }
            // 対応するURLを取得
            let url = imagePaths[i]
            // キャッシュに未登録ならば読み込み処理を行う
            if ImageCache.shared.image(for: url) == nil {
                // NSImageでURLから画像を生成できたらキャッシュに登録
                if let img = NSImage(contentsOf: url) {
                    ImageCache.shared.setImage(img, for: url)
                }
            }
        }
    }
}
