import SwiftUI

struct ContentView: View {
    @StateObject private var controller = PageControllerWrapper() // コントローラーを状態管理
    @State private var isThumbnailVisible = true // サムネイル表示状態
    
    // 追加：一定時間だけ動作をロックするフラグ
    @State private var canToggleThumbnail = true
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                PageControllerRepresentable(controller: controller)
                    .edgesIgnoringSafeArea(.all)

                MouseTrackingView { location in
                    
                    // フラグが false の間は無視
                    guard canToggleThumbnail else { return }
                    canToggleThumbnail = false

                    // 一定時間（例: 0.3秒）後に再度許可
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                      canToggleThumbnail = true
                    }
                    
                    
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
                ThumbnailScrollView(
                    imageURLs: controller.imagePaths,
                    currentIndex: $controller.selectedIndex,
                    isThumbnailVisible: $isThumbnailVisible
                )
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
        
        override func hitTest(_ point: NSPoint) -> NSView? {
            return nil
        }
    }
}
