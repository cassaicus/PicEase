import SwiftUI

struct ContentView: View {
    @StateObject private var controller = PageControllerWrapper() // コントローラーを状態管理
    @State private var isThumbnailVisible = true // サムネイル表示状態

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                PageControllerRepresentable(controller: controller)
                    .edgesIgnoringSafeArea(.all)

                MouseTrackingView { location in
                    let threshold: CGFloat = 150
                    if location.y <= threshold {
                        withAnimation {
                            isThumbnailVisible = true
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                isThumbnailVisible = false
                            }
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

struct MouseTrackingView: NSViewRepresentable {
    var onMove: (CGPoint) -> Void

    func makeNSView(context: Context) -> NSView {
        let trackingView = TrackingNSView()
        trackingView.onMove = onMove
        return trackingView
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    class TrackingNSView: NSView {
        var onMove: ((CGPoint) -> Void)?

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            trackingAreas.forEach(removeTrackingArea)
            let area = NSTrackingArea(rect: bounds,
                                      options: [.mouseMoved, .activeInKeyWindow, .inVisibleRect],
                                      owner: self, userInfo: nil)
            addTrackingArea(area)
        }

        override func mouseMoved(with event: NSEvent) {
            onMove?(convert(event.locationInWindow, from: nil))
        }
    }
}
