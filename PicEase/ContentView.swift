import SwiftUI

struct ContentView: View {
    @StateObject private var controller = PageControllerWrapper()
    @State private var isThumbnailVisible = true

    // Coordinatorを保持してResponder再設定できるように
    private let pageControllerCoordinator = PageControllerRepresentable.Coordinator()

    var body: some View {
        VStack(spacing: 0) {
            PageControllerRepresentable(controller: controller, coordinator: pageControllerCoordinator)
                .edgesIgnoringSafeArea(.all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onHover { hovering in
                    if hovering {
                        withAnimation {
                            isThumbnailVisible = true
                        }
                        // サムネイルを表示するタイミングでResponder復帰
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            pageControllerCoordinator.makeFirstResponder()
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                isThumbnailVisible = false
                            }
                        }
                    }
                }

            if isThumbnailVisible {
                ThumbnailScrollView(imageURLs: controller.imagePaths, currentIndex: $controller.selectedIndex)
                    .frame(height: 100)
                    .background(Color.black.opacity(0.8))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}
