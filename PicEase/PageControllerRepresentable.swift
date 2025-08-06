import SwiftUI
import AppKit

// MARK: PageControllerRepresentable
// SwiftUI用にNSPageControllerをラップ
struct PageControllerRepresentable: NSViewControllerRepresentable {
    @ObservedObject var controller: PageControllerWrapper

    func makeNSViewController(context: Context) -> NSPageController {
        // カスタムImagePageControllerを生成
        let pageController = ImagePageController(controller: controller)
        return pageController
    }

    func updateNSViewController(_ nsViewController: NSPageController, context: Context) {
        // 画像パスの更新確認
        let imagePaths = controller.imagePaths
        if imagePaths != nsViewController.arrangedObjects as? [URL] {
            nsViewController.arrangedObjects = imagePaths
        }
        guard !imagePaths.isEmpty else { return }
        // 選択インデックスの更新
        if imagePaths.indices.contains(controller.selectedIndex) {
            nsViewController.selectedIndex = controller.selectedIndex
        } else {
            nsViewController.selectedIndex = 0
        }
    }
}
