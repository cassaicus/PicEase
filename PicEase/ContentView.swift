import SwiftUI

/// アプリケーションのメインウィンドウのコンテンツを定義する、中心的なSwiftUIビューです。
struct ContentView: View {
    
    // MARK: - State Properties
    
    /// `NSPageController`のデータソースと状態を管理する共有オブジェクト。
    /// `@StateObject`としてここでインスタンス化され、このビューとその子ビューのライフサイクルにわたって維持されます。
    @StateObject private var controller = PageControllerWrapper()
    @EnvironmentObject var settingsStore: SettingsStore
    
    /// ウィンドウサイズが変更されたときに再描画を遅延実行するためのタスク。
    @State private var resizeTask: DispatchWorkItem?
    
    @State private var isHintIconVisible: Bool = false
    @State private var isPreviousButtonVisible: Bool = false
    @State private var isNextButtonVisible: Bool = false
    
    @State private var imageShake: CGFloat = 0
    
    // MARK: - Body
    
    var body: some View {
        // `GeometryReader` を使用して、親ビュー（この場合はウィンドウ全体）のサイズと座標系を取得します。
        GeometryReader { geometry in
            // 垂直方向にビューを配置するVStack。`spacing: 0`でビュー間の隙間をなくします。
            VStack(spacing: 0) {
                // ZStackを使用して、画像ビューと他のUI要素（マウストラッキング、オーバーレイ）を重ねて表示します。
                ZStack {
                    // AppKitの`NSPageController`をSwiftUIで表示するためのラッパービュー。
                    PageControllerRepresentable(controller: controller, settingsStore: settingsStore)
                        .modifier(ShakeEffect(animatableData: imageShake))
                    // 安全領域（ノッチなど）を無視して全画面に表示。
                        .edgesIgnoringSafeArea(.all)
                        .onReceive(NotificationCenter.default.publisher(for: .showThumbnail)) { _ in
                            withAnimation {
                                controller.isThumbnailVisible = true
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: .shakeImage)) { _ in
                            withAnimation {
                                imageShake += 1
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: .hideThumbnail)) { _ in
                            withAnimation {
                                controller.isThumbnailVisible = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                NotificationCenter.default.post(name: .refreshCurrentPage, object: nil)
                            }
                        }
                    
                    // 表示する画像がない場合に、「Open Folder」ボタンのオーバーレイを表示。
                    if controller.imagePaths.isEmpty {
                        OpenFolderOverlayView()
                    }
                    
                    MouseTrackingView { location in
                        handleMouseMovement(at: location, in: geometry.size)
                    }
                    
                    if isHintIconVisible {
                        VStack {
                            Spacer()
                            ThumbnailHintIconView {
                                withAnimation {
                                    isHintIconVisible = false
                                    controller.isThumbnailVisible = true
                                }
                            }
                            .padding(.bottom, 20)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    // 左（戻る）ボタン
                    if isPreviousButtonVisible {
                        HStack {
                            Button(action: {
                                if controller.selectedIndex > 0 {
                                    controller.selectedIndex -= 1
                                } else {
                                    withAnimation(.default) {
                                        imageShake += 1
                                    }
                                }
                            }) {
                                Text("<")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.leading, 20)
                            Spacer()
                        }
                        .transition(.opacity)
                    }
                    
                    // 右（進む）ボタン
                    if isNextButtonVisible {
                        HStack {
                            Spacer()
                            Button(action: {
                                if controller.selectedIndex < controller.imagePaths.count - 1 {
                                    controller.selectedIndex += 1
                                } else {
                                    withAnimation(.default) {
                                        imageShake += 1
                                    }
                                }
                            }) {
                                Text(">")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.trailing, 20)
                        }
                        .transition(.opacity)
                    }
                }
                
                // サムネイルバーとコントロールバーの表示/非表示を切り替え。
                if controller.isThumbnailVisible {
                    // 垂直方向にコントロールバーとサムネイルビューを配置。
                    VStack(spacing: 0) {
                        // ナビゲーションコントロールバー
                        ControlBarView(controller: controller, fitImageAction: fitImageToWindow)
                        
                        // サムネイルのスクロールビュー
                        ThumbnailScrollView(
                            imageURLs: controller.imagePaths,
                            currentIndex: $controller.selectedIndex,
                            isThumbnailVisible: $controller.isThumbnailVisible
                        )
                        .frame(height: 100) // 高さを100ポイントに固定
                        .background(Color.black.opacity(0.8)) // 半透明の黒い背景
                        // 下からスライドイン/アウトするアニメーション効果。
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            // ホバーボタン設定の変更を監視します。
            .onChange(of: settingsStore.showHoverButtons) {
                // 設定がオフになったら、ボタンが現在表示されていても非表示にする
                if !settingsStore.showHoverButtons {
                    withAnimation {
                        isPreviousButtonVisible = false
                        isNextButtonVisible = false
                    }
                }
            }
            // ウィンドウのサイズ変更を監視します。
            .onChange(of: geometry.size) {
                // ウィンドウリサイズが頻繁に発生するため、`DispatchWorkItem`で処理を遅延させ、最後の変更後にのみ実行（デバウンス）。
                resizeTask?.cancel() // 以前のタスクがあればキャンセル
                
                let task = DispatchWorkItem {
                    // `NSPageController`に現在のページを再描画するよう通知
                    NotificationCenter.default.post(name: .refreshCurrentPage, object: nil)
                }
                resizeTask = task
                
                // 0.35秒の遅延後にタスクを実行
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: task)
            }
        }
    }
    
    // MARK: - UI Logic Methods
    
    /// 現在表示されている画像をウィンドウサイズにフィットさせます。
    func fitImageToWindow() {
        // 現在のメインウィンドウと表示中の画像を取得
        guard let window = NSApp.mainWindow,
              controller.imagePaths.indices.contains(controller.selectedIndex),
              let image = NSImage(contentsOf: controller.imagePaths[controller.selectedIndex])
        else { return }
        
        let imageSize = image.size
        // ウィンドウが現在表示されているスクリーンの可視領域（メニューバーやDockを除く）を取得
        guard let screenVisibleFrame = window.screen?.visibleFrame else { return }
        
        // 画像を可視領域に収めるためのスケーリング比率を計算
        let scale = min(screenVisibleFrame.width / imageSize.width,
                        screenVisibleFrame.height / imageSize.height)
        
        // 新しいウィンドウサイズを計算
        let newWidth = imageSize.width * scale
        let newHeight = imageSize.height * scale
        
        // 新しいウィンドウの原点（左下の座標）を計算
        let currentFrame = window.frame

        // X座標：現在のウィンドウの中心が、新しいサイズの中心になるように設定
        var newX = currentFrame.origin.x + (currentFrame.width - newWidth) / 2

        // Y座標：可視領域の下端に合わせる
        let newY = screenVisibleFrame.minY

        // X座標が画面外に出ないように補正する
        // 左端より左に行かないようにする
        newX = max(newX, screenVisibleFrame.minX)
        // 右端より右に行かないようにする
        newX = min(newX, screenVisibleFrame.maxX - newWidth)
        
        // 新しいフレーム（位置とサイズ）を作成
        let newFrame = NSRect(x: newX, y: newY, width: newWidth, height: newHeight)
        
        // ウィンドウのフレームをアニメーション付きで更新
        window.setFrame(newFrame, display: true, animate:true)
    }
    
    // MARK: - Child Views
    
    /// 画像が読み込まれていないときに表示されるオーバーレイビュー。
    struct OpenFolderOverlayView: View {
        var body: some View {
            ZStack {
                // 半透明の黒い背景
                Color.black.opacity(0.8)
                
                // 「フォルダを開く」ボタン
                Button(action: {
                    // `.openFolder`通知を送信して、`ImagePageController`にフォルダ選択パネルを開かせる
                    NotificationCenter.default.post(name: .openFolder, object: nil)
                }) {
                    Text("Open Folder")
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle()) // 標準のボタンスタイルを無効化
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
        }
    }
    
    private func handleMouseMovement(at location: CGPoint, in size: CGSize) {
        // 設定でホバーボタンが無効になっている場合は何もしない
        guard settingsStore.showHoverButtons else { return }

        if controller.isThumbnailVisible {
            if isHintIconVisible || isPreviousButtonVisible || isNextButtonVisible {
                withAnimation {
                    isHintIconVisible = false
                    isPreviousButtonVisible = false
                    isNextButtonVisible = false
                }
            }
            return
        }
        
        // マウスカーソルのY座標がビューの下部25%にあるかを判定
        let shouldBeHintIconVisible = location.y < size.height * 0.25
        if isHintIconVisible != shouldBeHintIconVisible {
            withAnimation(.easeInOut(duration: 0.2)) {
                isHintIconVisible = shouldBeHintIconVisible
            }
        }
        
        // マウスカーソルのX座標が左側20%にあるかを判定
        let shouldBePreviousButtonVisible = location.x < size.width * 0.2
        if isPreviousButtonVisible != shouldBePreviousButtonVisible {
            withAnimation(.easeInOut(duration: 0.2)) {
                isPreviousButtonVisible = shouldBePreviousButtonVisible
            }
        }
        
        // マウスカーソルのX座標が右側20%にあるかを判定
        let shouldBeNextButtonVisible = location.x > size.width * (1 - 0.2)
        if isNextButtonVisible != shouldBeNextButtonVisible {
            withAnimation(.easeInOut(duration: 0.2)) {
                isNextButtonVisible = shouldBeNextButtonVisible
            }
        }
    }
}

/// ビューにシェイクアニメーションを適用するための`GeometryEffect`。
struct ShakeEffect: GeometryEffect {
    /// 揺れの強さ
    var amount: CGFloat = 10
    /// 揺れの回数
    var shakesPerUnit = 3
    /// アニメーション可能なデータ。この値が変化するとエフェクトが再計算される。
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        // `animatableData`（アニメーションのトリガー）が変化したときに、
        // `sin`関数を使ってX方向のオフセットを計算し、左右の揺れを表現する。
        ProjectionTransform(CGAffineTransform(
            translationX: amount * sin(
                animatableData * .pi * CGFloat(shakesPerUnit)), y: 0)
        )
    }
}

/// マウスカーソルの位置を継続的に追跡するための`NSViewRepresentable`ラッパー。
struct MouseTrackingView: NSViewRepresentable {
    var onMove: (CGPoint) -> Void // マウスが移動したときに呼び出されるコールバック
    
    func makeNSView(context: Context) -> NSView {
        let view = TrackingNSView()
        view.onMove = onMove
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    /// マウストラッキング機能を実装したカスタム`NSView`。
    class TrackingNSView: NSView {
        var onMove: ((CGPoint) -> Void)?
        
        // `updateTrackingAreas`は、ビューのサイズや位置が変わったときに呼び出されるため、
        // ここでトラッキングエリアを再設定するのが最も確実です。
        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            // 既存のトラッキングエリアをすべて削除して重複を防ぐ
            trackingAreas.forEach(removeTrackingArea)
            
            // 新しいトラッキングエリアを作成
            let area = NSTrackingArea(
                rect: bounds, // ビュー全体を追跡範囲とする
                options: [
                    .mouseMoved,         // マウス移動イベントを補足
                    .activeInKeyWindow,  // アプリがアクティブなときのみ追跡
                    .inVisibleRect       // ビューの可視部分のみ追跡
                ],
                owner: self,
                userInfo: nil
            )
            addTrackingArea(area)
        }
        
        // マウスが移動したときに呼び出される
        override func mouseMoved(with event: NSEvent) {
            // マウスのウィンドウ座標をビューのローカル座標に変換してコールバックを呼び出し
            onMove?(convert(event.locationInWindow, from: nil))
        }
        
        // このビューがクリックイベントを補足しないように`nil`を返す（イベントを下のビューに透過させる）。
        override func hitTest(_ point: NSPoint) -> NSView? {
            return nil
        }
    }
}
