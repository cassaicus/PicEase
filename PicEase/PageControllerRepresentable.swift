import SwiftUI
import AppKit

/// `NSPageController`をSwiftUIビュー階層内で使用するためのラッパー構造体です。
/// `NSViewControllerRepresentable`プロトコルに準拠することで、AppKitのビューコントローラとSwiftUIとの間で
/// データのやり取りやライフサイクルイベントの管理が可能になります。
struct PageControllerRepresentable: NSViewControllerRepresentable {

    // MARK: - Properties

    /// 親のSwiftUIビュー（`ContentView`）から渡される、アプリケーションの状態を管理するObservableObject。
    /// `@ObservedObject`としてこの変更を監視し、`updateNSViewController`をトリガーします。
    @ObservedObject var controller: PageControllerWrapper
    let settingsStore: SettingsStore

    // MARK: - NSViewControllerRepresentable Methods

    /// SwiftUIがこのビューを最初に表示するときに一度だけ呼び出され、`NSPageController`のインスタンスを生成します。
    /// - Parameter context: ビューコントローラとSwiftUIの間の調整役となるコンテキスト情報。
    /// - Returns: SwiftUIによって管理される`NSPageController`のインスタンス。
    func makeNSViewController(context: Context) -> NSPageController {
        // `ImagePageController`（NSPageControllerのカスタムサブクラス）を初期化します。
        // `controller`と`settingsStore`を渡すことで、`ImagePageController`が共有データモデルと設定にアクセスできるようになります。
        let pageController = ImagePageController(controller: controller, settingsStore: settingsStore)
        return pageController
    }

    /// SwiftUIビューの状態が変更され、AppKitのビューコントローラを更新する必要があるときに呼び出されます。
    /// - Parameters:
    ///   - nsViewController: `makeNSViewController`で作成された`NSPageController`のインスタンス。
    ///   - context: 現在の状態に関するコンテキスト情報。
    func updateNSViewController(_ nsViewController: NSPageController, context: Context) {
        // `controller`（SwiftUI側のデータソース）から最新の画像パスリストを取得します。
        let newImagePaths = controller.imagePaths

        // AppKit側の`arrangedObjects`とSwiftUI側の`imagePaths`に差異があるか確認します。
        // `arrangedObjects`は`NSPageController`が表示するコンテンツの配列です。
        if newImagePaths != nsViewController.arrangedObjects as? [URL] {
            // 差異があれば、`arrangedObjects`を最新のリストで更新します。
            nsViewController.arrangedObjects = newImagePaths
        }

        // 画像リストが空の場合は、これ以降の処理は不要です。
        guard !newImagePaths.isEmpty else { return }

        // SwiftUI側の`selectedIndex`が、AppKit側の`selectedIndex`と異なるか確認します。
        if nsViewController.selectedIndex != controller.selectedIndex {
            // `selectedIndex`が有効な範囲にあることを確認してから更新します。
            if newImagePaths.indices.contains(controller.selectedIndex) {
                nsViewController.selectedIndex = controller.selectedIndex
            } else {
                // 範囲外の場合は、安全のために0にリセットします。
                // （このロジックはPageControllerWrapper内にもありますが、二重で安全を確保しています）
                nsViewController.selectedIndex = 0
            }
        }
    }
}
