import SwiftUI

// 🔹 ボタンサイズの種類（共通定義として最上部に）
enum ButtonSize {
    case small
    case medium
    case large
}

// 🔹 メインビュー
struct ContentView: View {
    @StateObject private var controller = PageControllerWrapper() // ページコントローラの管理
    @State private var isThumbnailVisible = true // サムネイル表示フラグ
    @State private var canToggleThumbnail = true // サムネイル切り替え制御用フラグ
    @State private var hideTask: DispatchWorkItem? // 遅延で非表示にする処理
    
    var body: some View {
        VStack(spacing: 0) { // 縦方向に整列（隙間なし）
            ZStack {
                // 🔸 ページ表示領域（画像のビュー）
                PageControllerRepresentable(controller: controller)
                    .edgesIgnoringSafeArea(.all) // Safe Area を無視して全画面表示
                
//                // 🔸 メイン画像をクリックしたらサムネイルを隠す
//                Color.clear
//                     .contentShape(Rectangle())
//                     .onTapGesture {
//                         withAnimation {
//                             isThumbnailVisible = false
//                         }
//                     }
                
                ClickForwardingView {
                    withAnimation {
                        isThumbnailVisible = false
                    }
                }
                
                
                // 🔸 マウスの移動を監視するカスタムビュー
                MouseTrackingView { location in
                    guard canToggleThumbnail else { return } // 切り替え制御
                    canToggleThumbnail = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        canToggleThumbnail = true
                    }
                    
                    let threshold: CGFloat = 150 // マウスが上端から150pt以内なら表示
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
                
                // 🔸 フォルダが未選択の時に中央に表示する「Open Folder」ボタン
                if controller.imagePaths.isEmpty {
                    ZStack {
                        Color.black.opacity(0.8) // 背景：薄黒（画像が透ける）

                        Button(action: {
                            // フォルダ選択の通知を送信
                            NotificationCenter.default.post(name: .openFolder, object: nil)
                        }) {
                            Text("Open Folder") // ボタンのラベル
                                .padding(.horizontal, 24) // 左右の余白
                                .padding(.vertical, 12) // 上下の余白
                                .background(Color.white.opacity(0.1)) // 半透明の白背景
                                .foregroundColor(.white) // 文字色を白に
                                .cornerRadius(12) // ボタン角を丸く
                        }
                        .buttonStyle(PlainButtonStyle()) // macOSのデフォルト枠を消す
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // フルサイズに拡張
                    .edgesIgnoringSafeArea(.all) // SafeArea を無視して重ねる
                }
            }
            
            // 🔻 サムネイルとその上部メニュー
            if isThumbnailVisible {
                VStack(spacing: 0) {
                    // 🔸 メニュー部分（ナビゲーションボタンなど）
                    // 🔹 見栄えの良いカスタムメニューバー
                    
                    HStack(spacing: 16) {
                        // 左側のボタン群
                        moveButton("chevron.left", offset: -50, controller: controller, size: .large)
                        moveButton("chevron.left", offset: -10, controller: controller, size: .medium)
                        moveButton("chevron.left", offset: -1, controller: controller, size: .small)
                        
                        moveButton("chevron.right", offset: +1, controller: controller, size: .small)
                        moveButton("chevron.right", offset: +10, controller: controller, size: .medium)
                        moveButton("chevron.right", offset: +50, controller: controller, size: .large)
                        
                        // 🔹 最後のボタンのすぐ右にインデックス表示
                        let currentIndex = controller.imagePaths.isEmpty ? 0 : controller.selectedIndex + 1
                        let totalCount = controller.imagePaths.count
                        Text("\(currentIndex) / \(totalCount)")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.leading, 4) // ← ボタンと少し間隔をあける
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.black)

                    // 🔸 サムネイルのスクロールビュー
                    ThumbnailScrollView(
                        imageURLs: controller.imagePaths,
                        currentIndex: $controller.selectedIndex,
                        isThumbnailVisible: $isThumbnailVisible
                    )
                    .frame(height: 100) // 高さを100ptに固定
                    .background(Color.black.opacity(0.8)) // 背景色
                    .transition(.move(edge: .bottom).combined(with: .opacity)) // アニメーション付き表示
                }
            }
        }
    }
    
    // 🔸 サムネイルをスクロールさせる関数（未使用でも今後のために残す）
    func scrollThumbnail(by offset: Int) {
        let newIndex = min(max(0, controller.selectedIndex + offset), controller.imagePaths.count - 1)
        controller.selectedIndex = newIndex
    }
    
    
    /// 丸い透明ボタンを作る再利用可能なビュー
    @ViewBuilder
    func iconButton(_ systemName: String, isEmphasized: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: isEmphasized ? 22 : 16, weight: .medium))
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.15)) // 薄い白の丸背景
                .clipShape(Circle())
                .foregroundColor(.white) // アイコンは白
        }
        .buttonStyle(PlainButtonStyle()) // macOSの枠線を除去
    }
    
    
    @ViewBuilder
    func moveButton(_ systemName: String, offset: Int, controller: PageControllerWrapper, size: ButtonSize = .medium) -> some View {
        
        // 🔸 サイズごとの定数を switch で取得
        let (buttonSize, iconSize): (CGFloat, CGFloat) = {
            switch size {
            case .small:
                return (28, 14)
            case .medium:
                return (32, 15)
            case .large:
                return (35, 16)
            }
        }()
        
        Button(action: {
            let newIndex = min(max(0, controller.selectedIndex + offset), controller.imagePaths.count - 1)
            controller.selectedIndex = newIndex
        }) {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .medium))
                .frame(width: buttonSize, height: buttonSize)
                .background(Color.white.opacity(0.15))
                .clipShape(Circle())
                .foregroundColor(.white)
        }
        .buttonStyle(PlainButtonStyle())
    }


    
    
}


// 🔹 マウスの位置を監視するカスタムビュー（macOS用）
struct MouseTrackingView: NSViewRepresentable {
    var onMove: (CGPoint) -> Void // マウス移動時に呼ばれるクロージャ
    
    func makeNSView(context: Context) -> NSView {
        let trackingView = TrackingNSView()
        trackingView.onMove = onMove
        return trackingView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {} // 状態更新は不要
    
    class TrackingNSView: NSView {
        var onMove: ((CGPoint) -> Void)? // 移動イベント用のクロージャ
        
        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            trackingAreas.forEach(removeTrackingArea) // 既存エリアを削除
            let area = NSTrackingArea(rect: bounds,
                                      options: [.mouseMoved, .activeInKeyWindow, .inVisibleRect],
                                      owner: self, userInfo: nil)
            addTrackingArea(area) // 新しいトラッキングエリアを追加
        }
        
        override func mouseMoved(with event: NSEvent) {
            onMove?(convert(event.locationInWindow, from: nil)) // マウス座標を通知
        }
        
        override func hitTest(_ point: NSPoint) -> NSView? {
            return nil // クリックイベントを透過
        }
    }
}




struct ClickForwardingView: NSViewRepresentable {
    var onClick: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = ForwardingView()
        view.action = onClick
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    class ForwardingView: NSView {
        var action: (() -> Void)?

        override func mouseDown(with event: NSEvent) {
            action?()
        }

        override func hitTest(_ point: NSPoint) -> NSView? {
            return self
        }

        override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
            return true
        }

        override func mouseDragged(with event: NSEvent) {
            // 何もしない = スワイプなどをNSPageControllerに譲る
        }

        override func scrollWheel(with event: NSEvent) {
            // スクロールも譲る
            super.scrollWheel(with: event)
        }
    }
}



