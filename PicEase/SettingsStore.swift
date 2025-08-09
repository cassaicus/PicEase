import SwiftUI
import Combine

/// アプリケーションの設定を管理し、`UserDefaults`に永続化するObservableObjectです。
class SettingsStore: ObservableObject {

    // MARK: - UserDefaults Keys

    /// `UserDefaults`で使用するキーを定義するプライベートな列挙型。
    /// 文字列のハードコーディングを避け、タイプセーフを向上させます。
    private enum Keys {
        static let invertArrowKeys = "invertArrowKeys"
        static let enableMouseWheel = "enableMouseWheel"
        static let showHoverButtons = "showHoverButtons"
        static let useVerticalArrows = "useVerticalArrowsForNavigation"
    }

    // MARK: - Published Properties

    /// キーボードの矢印キーの操作を逆にするかどうか。
    /// `didSet`で変更を`UserDefaults`に保存します。
    @Published var invertArrowKeys: Bool {
        didSet {
            UserDefaults.standard.set(invertArrowKeys, forKey: Keys.invertArrowKeys)
        }
    }

    /// マウスホイールでのナビゲーションを有効にするかどうか。
    @Published var enableMouseWheel: Bool {
        didSet {
            UserDefaults.standard.set(enableMouseWheel, forKey: Keys.enableMouseWheel)
        }
    }

    /// 画像上に表示されるナビゲーションボタンを表示するかどうか。
    @Published var showHoverButtons: Bool {
        didSet {
            UserDefaults.standard.set(showHoverButtons, forKey: Keys.showHoverButtons)
        }
    }

    /// キーボードの上下矢印キーでのナビゲーションを有効にするかどうか。
    @Published var useVerticalArrowsForNavigation: Bool {
        didSet {
            UserDefaults.standard.set(useVerticalArrowsForNavigation, forKey: Keys.useVerticalArrows)
        }
    }

    // MARK: - Initialization

    /// `SettingsStore`の新しいインスタンスを初期化します。
    /// `UserDefaults`から保存されている値を読み込み、各プロパティの初期値として設定します。
    /// 値が存在しない場合は、デフォルト値（`false`, `true`, `true`）が使用されます。
    init() {
        // UserDefaultsから値を読み込む、またはデフォルト値を設定
        self.invertArrowKeys = UserDefaults.standard.bool(forKey: Keys.invertArrowKeys)
        // enableMouseWheelはデフォルトでtrueにしたいので、object(forKey:)でnilチェックを行う
        if UserDefaults.standard.object(forKey: Keys.enableMouseWheel) == nil {
            self.enableMouseWheel = true
        } else {
            self.enableMouseWheel = UserDefaults.standard.bool(forKey: Keys.enableMouseWheel)
        }
        // showHoverButtonsも同様にデフォルトでtrue
        if UserDefaults.standard.object(forKey: Keys.showHoverButtons) == nil {
            self.showHoverButtons = true
        } else {
            self.showHoverButtons = UserDefaults.standard.bool(forKey: Keys.showHoverButtons)
        }
        self.useVerticalArrowsForNavigation = UserDefaults.standard.bool(forKey: Keys.useVerticalArrows)
    }
}
