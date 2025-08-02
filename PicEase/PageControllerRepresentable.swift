// SwiftUIフレームワークをインポートし、ビュー構築に必要な型を利用可能にする
import SwiftUI
// AppKitフレームワークをインポートし、NSPageControllerなどのAppKit要素を利用可能にする
import AppKit

// SwiftUI上でNSPageControllerを扱うためのRepresentable構造体を定義
struct PageControllerRepresentable: NSViewControllerRepresentable {
    // ObservableObjectとして管理しているラッパークラスを監視し、変更をビューに反映する
    @ObservedObject var controller: PageControllerWrapper
    // Coordinatorインスタンスを保持し、SwiftUIとAppKit間の参照を橋渡しする
    let coordinator: Coordinator
    
    // SwiftUIが内部的に利用するCoordinatorクラスを定義
    class Coordinator {
        // 実際に生成されるImagePageControllerへの弱参照を保持
        var pageController: ImagePageController?
    }
    
    // SwiftUIからCoordinatorを要求された際に呼ばれるメソッド
    func makeCoordinator() -> Coordinator {
        // Coordinatorの新規インスタンスを生成して返却
        Coordinator()
    }
    
    // SwiftUIがこのRepresentableに対応するNSViewControllerを必要としたときに呼ばれる
    func makeNSViewController(context: Context) -> NSPageController {
        // カスタムのImagePageControllerを、ラッパーデータを渡して初期化
        let pc = ImagePageController(controller: controller)
        // Coordinatorに生成したPageControllerの参照を保存して後続処理で利用可能にする
        context.coordinator.pageController = pc
        // SwiftUIに返却し、ビュー階層に配置を委ねる
        return pc
    }
    
    // SwiftUIの状態(@ObservedObjectなど)が変更された際に呼ばれる更新用メソッド
    func updateNSViewController(_ nsViewController: NSPageController, context: Context) {
        // ラッパークラスから最新の画像URL配列を取得
        let imagePaths = controller.imagePaths
        
        // NSPageControllerに設定済みのarrangedObjectsと異なる場合のみ更新して無駄な再設定を防止
        if imagePaths != nsViewController.arrangedObjects as? [URL] {
            // arrangedObjectsプロパティに新しいURL配列を代入し、ページ群を更新
            nsViewController.arrangedObjects = imagePaths
        }
        
        // 選択インデックスが有効範囲内なら、PageControllerのselectedIndexを同期
        if imagePaths.indices.contains(controller.selectedIndex) {
            // SwiftUI側のselectedIndexをNSPageControllerに反映
            nsViewController.selectedIndex = controller.selectedIndex
        }
    }
}
