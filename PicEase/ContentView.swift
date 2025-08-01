import SwiftUI

struct ContentView: View {
    @StateObject private var controller = PageControllerWrapper()

    var body: some View {
        VStack(spacing: 0) {
            PageControllerRepresentable(controller: controller)
                .edgesIgnoringSafeArea(.all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            ThumbnailScrollView(imageURLs: controller.imagePaths, currentIndex: $controller.selectedIndex)
                .frame(height: 100)
                .background(Color.black.opacity(0.8))
        }
    }
}
