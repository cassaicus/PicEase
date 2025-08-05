import SwiftUI

struct ContentView: View {
    @StateObject private var controller = PageControllerWrapper()
    @State private var isThumbnailVisible = true
    @State private var canToggleThumbnail = true
    @State private var hideTask: DispatchWorkItem?

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack {
                    PageControllerRepresentable(controller: controller)
                        .edgesIgnoringSafeArea(.all)

                    MouseTrackingView { location in
                        guard canToggleThumbnail else { return }
                        canToggleThumbnail = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            canToggleThumbnail = true
                        }

                        let threshold: CGFloat = 150
                        if location.y <= threshold {
                            withAnimation {
                                isThumbnailVisible = true
                            }
                            hideTask?.cancel()
                        } else {
                            let task = DispatchWorkItem {
                                withAnimation {
                                    isThumbnailVisible = false
                                }
                            }
                            hideTask?.cancel()
                            hideTask = task
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: task)
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

            //中央に「フォルダを開く」ボタン（画像未読み込み時のみ表示）
            if controller.imagePaths.isEmpty {
                VStack {
                    Button(action: {
                        NotificationCenter.default.post(name: .openFolder, object: nil)
                    }) {
                        Text("Open Folder")
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle()) // ← これでグレーの縁取りを削除
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.8))
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
