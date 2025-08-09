import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore

    var body: some View {
        Form {
            Toggle("キーボードの←/→キーの操作を逆にする", isOn: $settingsStore.invertArrowKeys)
            Toggle("マウスホイールでのナビゲーションを有効にする", isOn: $settingsStore.enableMouseWheel)
            Toggle("画像上のナビゲーションボタンを表示する", isOn: $settingsStore.showHoverButtons)
        }
        .padding(20)
    }
}
