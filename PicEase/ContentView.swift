import SwiftUI

struct ContentView: View {
    @StateObject private var controller = PageControllerWrapper() // コントローラーを状態管理
    @State private var isThumbnailVisible = true // サムネイル表示状態

    var body: some View {
        VStack(spacing: 0) {
            // ページビュー表示部分
            PageControllerRepresentable(controller: controller)
                .edgesIgnoringSafeArea(.all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onHover { hovering in
                    // ホバー時にサムネイル表示／非表示を制御
                    if hovering {
                        withAnimation {
                            isThumbnailVisible = true
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                isThumbnailVisible = false
                            }
                        }
                    }
                }

            // サムネイルビュー
            if isThumbnailVisible {
                ThumbnailScrollView(imageURLs: controller.imagePaths, currentIndex: $controller.selectedIndex)
                    .frame(height: 100)
                    .background(Color.black.opacity(0.8))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}
