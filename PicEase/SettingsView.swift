import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Toggle("キーボードの←/→キーの操作を逆にする", isOn: $settingsStore.invertArrowKeys)
                Toggle("マウスホイールでのナビゲーションを有効にする", isOn: $settingsStore.enableMouseWheel)
                Toggle("画像上のナビゲーションボタンを表示する", isOn: $settingsStore.showHoverButtons)
                Toggle("キーボードの↑/↓キーで進む/戻る", isOn: $settingsStore.useVerticalArrowsForNavigation)
            }
            .padding()

            HStack {
                Spacer()
                Button("閉じる") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction) // Allow Escape key to close
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}
