
import SwiftUI

//  ボタンサイズの種類（共通定義として最上部に）
enum ButtonSize {
    case small
    case medium
    case large
}

//  メインビュー
struct ContentView: View {
    // ページコントローラの管理
    
    @StateObject private var controller = PageControllerWrapper()
    // サムネイル表示フラグ
    @State private var isThumbnailVisible = true
    // サムネイル切り替え制御用フラグ
    
    @State private var canToggleThumbnail = true
    // 遅延で非表示にする処理
    
    @State private var hideTask: DispatchWorkItem?
    
    var body: some View {
        // 縦方向に整列（隙間なし）
        VStack(spacing: 0) {
            ZStack {
                // ページ表示領域（画像のビュー）
                PageControllerRepresentable(controller: controller)
                // Safe Area を無視して全画面表示
                    .edgesIgnoringSafeArea(.all)
                
                    .onReceive(NotificationCenter.default.publisher(for: .mainImageClicked)) { _ in
                        withAnimation {
                            isThumbnailVisible = false
                        }
                    }
                // マウスの移動を監視するカスタムビュー
                MouseTrackingView { location in
                    guard canToggleThumbnail else { return } // 切り替え制御
                    canToggleThumbnail = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        canToggleThumbnail = true
                    }
                    // マウスが上端から150pt以内なら表示
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
                
                //  フォルダが未選択の時に中央に表示する「Open Folder」ボタン
                if controller.imagePaths.isEmpty {
                    ZStack {
                        // 背景：薄黒（画像が透ける）
                        Color.black.opacity(0.8)
                        
                        Button(action: {
                            // フォルダ選択の通知を送信
                            NotificationCenter.default.post(name: .openFolder, object: nil)
                        }) {
                            // ボタンのラベル
                            Text("Open Folder")
                            // 左右の余白
                                .padding(.horizontal, 24)
                            // 上下の余白
                                .padding(.vertical, 12)
                            // 半透明の白背景
                                .background(Color.white.opacity(0.1))
                            // 文字色を白に
                                .foregroundColor(.white)
                            // ボタン角を丸く
                                .cornerRadius(12)
                        }
                        // macOSのデフォルト枠を消す
                        .buttonStyle(PlainButtonStyle())
                    }
                    // フルサイズに拡張
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    // SafeArea を無視して重ねる
                    .edgesIgnoringSafeArea(.all)
                }
            }
            
            // サムネイルとその上部メニュー
            if isThumbnailVisible {
                VStack(spacing: 0) {
                    // メニュー部分（ナビゲーションボタンなど）
                    // 見栄えの良いカスタムメニューバー
                    
                    HStack(spacing: 16) {
                        
                        iconButton("arrow.up.left.and.arrow.down.right") {
                            fitImageToWindow()
                        }
                        // 左側のボタン群
                        moveButton("chevron.left", offset: -50, controller: controller, size: .large)
                        moveButton("chevron.left", offset: -10, controller: controller, size: .medium)
                        moveButton("chevron.left", offset: -1, controller: controller, size: .small)
                        
                        moveButton("chevron.right", offset: +1, controller: controller, size: .small)
                        moveButton("chevron.right", offset: +10, controller: controller, size: .medium)
                        moveButton("chevron.right", offset: +50, controller: controller, size: .large)
                        
                        // 最後のボタンのすぐ右にインデックス表示
                        let currentIndex = controller.imagePaths.isEmpty ? 0 : controller.selectedIndex + 1
                        let totalCount = controller.imagePaths.count
                        Text("\(currentIndex) / \(totalCount)")
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .medium))
                        // ← ボタンと少し間隔をあける
                            .padding(.leading, 4)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    
                    // サムネイルのスクロールビュー
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
    
    //  サムネイルをスクロールさせる関数（未使用でも今後のために残す）
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
            // 薄い白の丸背景
                .background(Color.white.opacity(0.15))
                .clipShape(Circle())
            // アイコンは白
                .foregroundColor(.white)
        }
        // macOSの枠線を除去
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    func moveButton(_ systemName: String, offset: Int, controller: PageControllerWrapper, size: ButtonSize = .medium) -> some View {
        
        // サイズごとの定数を switch で取得
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
    
    func fitImageToWindow() {
        guard
            let window = NSApp.mainWindow,
            let screen = window.screen
        else { return }
        
        // 1. 利用可能領域（メニューバー＋Dockを除いた画面領域）を取得
        let availFrame = screen.visibleFrame
        
        // 2. ウィンドウのアスペクト比制約を解除
        window.contentAspectRatio = NSSize(width: 0, height: 0)
        
        // 3. フレームをそのまま利用可能領域に合わせる
        window.setFrame(availFrame, display: true, animate: true)
    }
}

// マウスの位置を監視するカスタムビュー（macOS用）
struct MouseTrackingView: NSViewRepresentable {
    var onMove: (CGPoint) -> Void // マウス移動時に呼ばれるクロージャ
    
    func makeNSView(context: Context) -> NSView {
        let trackingView = TrackingNSView()
        trackingView.onMove = onMove
        return trackingView
    }
    
    // 状態更新は不要
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    class TrackingNSView: NSView {
        // 移動イベント用のクロージャ
        var onMove: ((CGPoint) -> Void)?
        
        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            // 既存エリアを削除
            trackingAreas.forEach(removeTrackingArea)
            let area = NSTrackingArea(
                rect: bounds,
                options: [.mouseMoved, .activeInKeyWindow, .inVisibleRect],
                owner: self, userInfo: nil
            )
            // 新しいトラッキングエリアを追加
            addTrackingArea(area)
        }
        
        override func mouseMoved(with event: NSEvent) {
            // マウス座標を通知
            onMove?(convert(event.locationInWindow, from: nil))
        }
        
        override func hitTest(_ point: NSPoint) -> NSView? {
            // クリックイベントを透過
            return nil
        }
    }
}
