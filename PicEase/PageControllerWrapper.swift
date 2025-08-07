import Foundation
import Combine

/// SwiftUIビューとAppKitコンポーネント（NSPageController）の間で
/// 画像ブラウジングの状態を共有するためのデータ管理クラスです。
/// `ObservableObject`に準拠しており、プロパティの変更がUIに自動的に通知されます。
class PageControllerWrapper: ObservableObject {

    // MARK: - Published Properties

    /// 表示対象となる画像ファイルのURLリスト。
    /// `@Published`プロパティラッパーにより、この配列への変更（追加、削除、置換）が
    /// このオブジェクトを監視しているSwiftUIビューに通知され、UIが自動的に更新されます。
    @Published var imagePaths: [URL] = [] {
        /// `imagePaths`が変更された直後に呼び出されます。
        /// `selectedIndex`が新しいリストの有効な範囲内に収まるように調整し、
        /// アプリケーションのクラッシュや予期せぬ動作を防ぎます。
        didSet {
            // 現在の選択インデックスが、新しい`imagePaths`の数以上（つまり範囲外）になったかチェック
            if selectedIndex >= imagePaths.count {
                // インデックスをリストの最後の有効なインデックスに設定。リストが空の場合は0になる。
                selectedIndex = max(0, imagePaths.count - 1)
            }
        }
    }

    /// 現在選択されている画像の、`imagePaths`配列内でのインデックス。
    /// こちらも`@Published`が付いているため、インデックスの変更はUIに即座に反映されます。
    /// （例：サムネイルビューのハイライト、ページコントローラの表示ページなど）
    @Published var selectedIndex: Int = 0 {
        /// `selectedIndex`が変更された直後に呼び出されます。
        /// 主に、プログラムによるインデックス変更が範囲外にならないように安全性を確保します。
        didSet {
            // `selectedIndex`が`imagePaths`の有効範囲を超えていないかチェック
            if selectedIndex >= imagePaths.count {
                // インデックスをリストの最後の有効なインデックスに設定。リストが空の場合は0になる。
                selectedIndex = max(0, imagePaths.count - 1)
            }
        }
    }

    // MARK: - Public Methods

    /// 新しい画像URLのリストでデータモデルを更新します。
    /// 選択インデックスは自動的に先頭（0）にリセットされます。
    /// - Parameter urls: 新しく表示する画像URLの配列。
    func setImages(_ urls: [URL]) {
        // 画像のURLリストを更新
        imagePaths = urls
        // 選択インデックスを0にリセット
        selectedIndex = 0
    }

    /// 新しい画像URLのリストと、初期選択インデックスを指定してデータモデルを更新します。
    /// - Parameters:
    ///   - urls: 新しく表示する画像URLの配列。
    ///   - currentIndex: 初期状態で選択する画像のインデックス。
    func setImagesIndex(_ urls: [URL], _ currentIndex: Int) {
        // URLリストが空の場合は何もしない
        guard !urls.isEmpty else {
            // 空のリストを設定してクリアする
            imagePaths = []
            selectedIndex = 0
            return
        }

        // 画像のURLリストを更新
        imagePaths = urls

        // 指定された`currentIndex`が有効な範囲内にあるかチェック
        if urls.indices.contains(currentIndex) {
            // 有効なら、そのインデックスを選択状態にする
            selectedIndex = currentIndex
        } else {
            // 無効な場合は、安全のために先頭のインデックスを選択状態にする
            selectedIndex = 0
        }
    }
}
