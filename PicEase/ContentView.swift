
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
    //リザイズのwindowSize
    @State private var windowSize: CGSize = .zero
    //リサイズタスク
    @State private var resizeTask: DispatchWorkItem?
    
    var body: some View {
        GeometryReader { geometry in
            // 縦方向に整列（隙間なし）
            VStack(spacing: 0) {
                ZStack {
                    // ページ表示領域（画像のビュー）
                    PageControllerRepresentable(controller: controller)
                        .edgesIgnoringSafeArea(.all)
                        .onReceive(NotificationCenter.default.publisher(for: .mainImageClicked)) { _ in
                            withAnimation {
                                if isThumbnailVisible {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                        //0.35後にrefreshCurrentPageを呼び出し再描写
                                        NotificationCenter.default.post(name: .refreshCurrentPage, object: nil)
                                    }
                                }
                                isThumbnailVisible = false
                            }
                        }
                    
                    MouseTrackingView { location in
                        // 切り替え制御
                        guard canToggleThumbnail else { return }
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
                            //マウスカーソルが反れて２秒後に動く
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: task)
                        }
                    }
                    
                    //  フォルダが未選択の時に中央に表示する「Open Folder」ボタン
                    if controller.imagePaths.isEmpty {
                        ZStack {
                            // 背景：薄黒（画像が透ける）
                            Color.black.opacity(0.8)
                            // Open Folderボタン
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
                            // 戻るのボタン群
                            moveButton("chevron.left", offset: -50, controller: controller, size: .large)
                            moveButton("chevron.left", offset: -10, controller: controller, size: .medium)
                            moveButton("chevron.left", offset: -1, controller: controller, size: .small)
                            // 進むのボタン群
                            moveButton("chevron.right", offset: +1, controller: controller, size: .small)
                            moveButton("chevron.right", offset: +10, controller: controller, size: .medium)
                            moveButton("chevron.right", offset: +50, controller: controller, size: .large)
                            
                            // 最後のボタンのすぐ右にインデックス表示
                            let currentIndex = controller.imagePaths.isEmpty ? 0 : controller.selectedIndex + 1
                            let totalCount = controller.imagePaths.count
                            Text("\(currentIndex) / \(totalCount)")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .medium))
                            // ボタンと少し間隔をあける
                                .padding(.leading, 4)
                            
                            //fitImageボタン
                            iconButton("arrow.up.left.and.down.right.and.arrow.up.right.and.down.left") {
                                //ウィンドウサイズを画像にフィットするように変更
                                fitImageToWindow()
                                //refreshCurrentPageを呼び出し再描写
                                NotificationCenter.default.post(name: .refreshCurrentPage, object: nil)
                            }
                            
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
//            .onAppear {
//                windowSize = geometry.size
//            }
            .onChange(of: geometry.size) {
                //ウィンドウのリサイズをキャッチ
                // 既存タスクをキャンセル
                resizeTask?.cancel()
                // 新しいタスクを作成
                let task = DispatchWorkItem {
                    NotificationCenter.default.post(
                        name: .refreshCurrentPage,
                        object: nil
                    )
                }
                resizeTask = task
                // 0.35秒後にタスクを実行
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.35,
                    execute: task
                )
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
        guard let window = NSApp.mainWindow,
              let screen = window.screen else { return }
        // 画像読み込み＆サイズ取得
        guard controller.imagePaths.indices.contains(controller.selectedIndex),
              let image = NSImage(contentsOf: controller.imagePaths[controller.selectedIndex]) else {
            return
        }
        let imgSize = image.size
        // 利用可能領域／スケール
        let visible = screen.visibleFrame
        let scale = min(visible.width / imgSize.width,
                        visible.height / imgSize.height)
        let newWidth  = imgSize.width  * scale
        let newHeight = imgSize.height * scale
        // 現在位置を取得
        let currentOrigin = window.frame.origin
        // X のクランプ範囲を計算
        let minX = visible.minX
        let maxX = visible.maxX - newWidth
        // currentOrigin.x を [minX…maxX] の範囲内に制限
        let newX = min(max(currentOrigin.x, minX), maxX)
        // Y 位置は0固定（必要なら同様にクランプ可）
        let newY: CGFloat = 0.0
        // フレーム適用
        window.setFrame(
            NSRect(x: newX, y: newY, width: newWidth, height: newHeight),
            display: true,
            animate: true
        )
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
}
