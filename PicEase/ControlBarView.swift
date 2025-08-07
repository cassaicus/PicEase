import SwiftUI

/// ナビゲーションボタン、画像インデックス、フィットボタンを含むコントロールバーを表示するSwiftUIビューです。
struct ControlBarView: View {

    // MARK: - Properties

    /// 親ビューから渡される、アプリケーションの状態を管理するObservableObject。
    /// `@ObservedObject`として受け取り、`controller`内の`@Published`プロパティの変更を検知してビューを再描画します。
    @ObservedObject var controller: PageControllerWrapper

    /// ウィンドウを現在の画像のサイズにフィットさせるためのアクション。親ビュー（ContentView）からクロージャとして渡されます。
    var fitImageAction: () -> Void

    // MARK: - Body

    var body: some View {
        // 水平方向にコントロールを配置するHStack
        HStack(spacing: 16) {
            // MARK: Navigation Buttons
            // 50画像戻るボタン（大）
            moveButton(systemName: "chevron.left", offset: -50, size: .large)
            // 10画像戻るボタン（中）
            moveButton(systemName: "chevron.left", offset: -10, size: .medium)
            // 1画像戻るボタン（小）
            moveButton(systemName: "chevron.left", offset: -1, size: .small)

            // 1画像進むボタン（小）
            moveButton(systemName: "chevron.right", offset: 1, size: .small)
            // 10画像進むボタン（中）
            moveButton(systemName: "chevron.right", offset: 10, size: .medium)
            // 50画像進むボタン（大）
            moveButton(systemName: "chevron.right", offset: 50, size: .large)

            // MARK: Image Index Display
            // 現在の画像インデックスと総画像数を表示
            let currentIndex = controller.imagePaths.isEmpty ? 0 : controller.selectedIndex + 1
            let totalCount = controller.imagePaths.count
            Text("\(currentIndex) / \(totalCount)")
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .medium))
                .padding(.leading, 4) // 左のボタンとの間に少し余白を追加

            // MARK: Fit Image Button
            // 画像をウィンドウにフィットさせるボタン
            iconButton(systemName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left", action: fitImageAction)

        }
        .padding(.vertical, 6)       // 上下のパディング
        .padding(.horizontal, 12)    // 左右のパディング
        .frame(maxWidth: .infinity)  // 横幅を最大まで広げる
        .background(Color.black)     // 背景色を黒に設定
    }

    // MARK: - View Builders

    /// ナビゲーション用のボタンを生成するプライベートなViewBuilder。
    /// - Parameters:
    ///   - systemName: ボタンに表示するSF Symbolの名前。
    ///   - offset: ボタンが押されたときに移動するインデックスのオフセット量。
    ///   - size: ボタンのサイズ（.small, .medium, .large）。
    @ViewBuilder
    private func moveButton(systemName: String, offset: Int, size: ButtonSize) -> some View {
        // `ButtonSize`に応じて、ボタンのフレームサイズとアイコンのフォントサイズを決定
        let (buttonSize, iconSize): (CGFloat, CGFloat) = {
            switch size {
            case .small:
                return (28, 14)
            case .medium:
                return (32, 15)
            case .large:
                return (35, 16)
            }
        }()

        // ボタンの定義
        Button(action: {
            // 新しいインデックスを計算。0未満や総数以上にならないようにクランプ（範囲内に収める）。
            let newIndex = min(max(0, controller.selectedIndex + offset), controller.imagePaths.count - 1)
            // 状態の更新をメインスレッドで非同期に実行し、UI更新の競合を防ぐ
            DispatchQueue.main.async {
                // 計算した新しいインデックスをコントローラに設定
                controller.selectedIndex = newIndex
            }
        }) {
            // ボタンの見た目（アイコン）
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .medium))
                .frame(width: buttonSize, height: buttonSize)
                .background(Color.white.opacity(0.15)) // 半透明の白い円形の背景
                .clipShape(Circle()) // 円形にクリップ
                .foregroundColor(.white) // アイコンの色を白に
        }
        .buttonStyle(PlainButtonStyle()) // macOS標準のボタン枠線を削除
    }

    ///汎用的なアイコンボタンを生成するプライベートなViewBuilder。
    /// - Parameters:
    ///   - systemName: ボタンに表示するSF Symbolの名前。
    ///   - action: ボタンが押されたときに実行されるクロージャ。
    @ViewBuilder
    private func iconButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.15))
                .clipShape(Circle())
                .foregroundColor(.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// ボタンのサイズを定義するための列挙型。
enum ButtonSize {
    case small
    case medium
    case large
}
