import SwiftUI

struct SettingsView: View {
    // NOTE: These will be connected to a persistent store later.
    @State private var invertArrowKeys = false
    @State private var enableMouseWheel = true
    @State private var showHoverButtons = true

    var body: some View {
        Form {
            Toggle("キーボードの←/→キーの操作を逆にする", isOn: $invertArrowKeys)
            Toggle("マウスホイールでのナビゲーションを有効にする", isOn: $enableMouseWheel)
            Toggle("画像上のナビゲーションボタンを表示する", isOn: $showHoverButtons)
        }
        .padding(20)
    }
}
