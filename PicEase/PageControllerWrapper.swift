import Foundation

// ページコントロール用のデータ管理クラス
class PageControllerWrapper: ObservableObject {
    // 表示する画像ファイルのURL配列
    @Published var imagePaths: [URL] = [] {
        didSet {
            // 選択インデックスが範囲外にならないように調整
            if selectedIndex >= imagePaths.count {
                selectedIndex = max(0, imagePaths.count - 1)
            }
        }
    }
    // 現在選択中のインデックス
    @Published var selectedIndex: Int = 0 {
        didSet {
            // 同様にインデックスが範囲外か確認
            if selectedIndex >= imagePaths.count {
                selectedIndex = max(0, imagePaths.count - 1)
            }
        }
    }
    // 新しい画像リストを設定
    func setImages(_ urls: [URL]) {
        //imagePathsにURLを代入して画像を表示させる
        imagePaths = urls
        // 最初の画像を選択状態に
        selectedIndex = 0
    }
    // 新しい画像リストとインデックス数を設定
    func setImagesIndex(_ urls: [URL], _ currentIndex: Int) {
        guard !urls.isEmpty else { return }
        imagePaths = urls
        // インデックスが範囲外にならないように調整
        if urls.indices.contains(currentIndex) {
            selectedIndex = currentIndex
        } else {
            selectedIndex = 0
        }
    }
}
