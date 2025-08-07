
import SwiftUI
import ImageIO

/// 画像のサムネイルを水平方向にスクロール表示するSwiftUIビューです。
struct ThumbnailScrollView: View {
    
    // MARK: - Properties
    
    /// 表示するすべての画像のURLリスト。親ビューから提供されます。
    let imageURLs: [URL]
    
    /// 現在選択されている画像のインデックス。親ビュー（ContentView）と双方向にバインディングされます。
    /// このビューでサムネイルがタップされると、この値が更新され、親ビューに即座に反映されます。
    @Binding var currentIndex: Int
    
    /// サムネイルバー全体の表示状態。親ビューとバインディングされています。
    /// このビューが表示されたときに、現在選択中のサムネイルまでスクロールするために使用します。
    @Binding var isThumbnailVisible: Bool
    
    /// 非同期で読み込まれたサムネイル画像をキャッシュするためのディクショナリ。
    /// `[URL: NSImage]` の形式で、一度読み込んだ画像をメモリに保持し、再読み込みを防ぎます。
    @State private var thumbnails: [URL: NSImage] = [:]
    
    // MARK: - Body
    
    var body: some View {
        // `ScrollViewReader` を使用して、特定のビュー（この場合はサムネイル）へプログラム的にスクロールできるようにします。
        ScrollViewReader { scrollProxy in
            // 水平方向のスクロールビュー。インジケータ（スクロールバー）は表示します。
            ScrollView(.horizontal, showsIndicators: true) {
                // `LazyHStack` は、ビューが表示されるまでコンテンツの作成を遅延させ、パフォーマンスを向上させます。
                LazyHStack(spacing: 8) {
                    // `imageURLs`をインデックス付きでループ処理します。
                    ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                        // 現在のサムネイルが選択状態にあるかどうかを判断
                        let isSelected = index == currentIndex
                        
                        // サムネイル画像を表示するZStack
                        ZStack {
                            // `thumbnails`ディクショナリに画像がキャッシュされていれば表示
                            if let image = thumbnails[url] {
                                Image(nsImage: image)
                                    .resizable() // フレームに合わせてリサイズ可能にする
                                    .aspectRatio(contentMode: .fill) // アスペクト比を保ちつつ、フレームを埋める
                            } else {
                                // 画像がまだ読み込まれていない場合は、グレーのプレースホルダーを表示
                                Color.gray
                            }
                        }
                        .frame(width: 80, height: 80) // サムネイルのサイズを固定
                        .clipped() // フレーム外にはみ出した部分をクリッピング
                        .border(isSelected ? Color.blue : Color.clear, width: 2) // 選択されていれば青い枠線を表示
                        .id(index) // `ScrollViewReader`がこのビューを識別するためのID
                        .onTapGesture {
                            // サムネイルがタップされたら、`currentIndex`を更新
                            currentIndex = index
                            // 同時に、`NSPageController`に直接インデックス変更を通知（より速い応答のため）
                            NotificationCenter.default.post(name: .thumbnailSelected, object: index)
                        }
                        .onAppear {
                            // このサムネイルビューが画面に表示され、かつ画像がまだ読み込まれていない場合に非同期ロードを開始
                            if thumbnails[url] == nil {
                                loadThumbnailAsync(for: url)
                            }
                        }
                    }
                }
                .padding(.horizontal) // 左右に余白を追加
            }
            // `currentIndex`が変更されたのを検知
            .onChange(of: currentIndex) { _, newIndex in
                // アニメーション付きで、新しく選択されたサムネイルが中央に来るようにスクロール
                withAnimation {
                    scrollProxy.scrollTo(newIndex, anchor: .center)
                }
            }
            // サムネイルバーの表示状態(`isThumbnailVisible`)が変更されたのを検知
            .task(id: isThumbnailVisible) {
                // サムネイルバーが表示された（`true`になった）瞬間に、
                // 現在選択中のサムネイルまでスクロールします。
                if isThumbnailVisible {
                    scrollProxy.scrollTo(currentIndex, anchor: .center)
                }
            }
        }
    }
    
    // MARK: - Thumbnail Loading
    
    /// 指定されたURLの画像を非同期で読み込み、サムネイルを生成します。
    /// - Parameter url: サムネイルを生成する元の画像のURL。
    private func loadThumbnailAsync(for url: URL) {
        // UIをブロックしないように、バックグラウンドスレッドで処理を実行
        DispatchQueue.global(qos: .userInitiated).async {
            // サムネイルの表示サイズ（ポイント単位）
            let targetSize = CGSize(width: 80, height: 80)
            // Retinaディスプレイなどに対応するため、画面のスケールファクターを取得
            let scaleFactor = NSScreen.main?.backingScaleFactor ?? 2.0
            // 実際に生成する画像のピクセルサイズを計算
            let pixelSize = CGSize(width: targetSize.width * scaleFactor, height: targetSize.height * scaleFactor)
            
            // URLからCGImageSourceを作成。画像ファイルへの参照を効率的に扱います。
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return }
            
            // サムネイル生成のためのオプションを設定
            let options: [NSString: Any] = [
                // オリジナル画像から常にサムネイルを生成（キャッシュされたサムネイルデータがあっても無視）
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                // サムネイルの最大ピクセルサイズを指定。アスペクト比は維持されます。
                kCGImageSourceThumbnailMaxPixelSize: max(pixelSize.width, pixelSize.height),
                // 画像が持つ回転や方向の情報をサムネイルに適用
                kCGImageSourceCreateThumbnailWithTransform: true
            ]
            
            // オプションを使ってサムネイル画像を生成
            if let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
                // 生成したCGImageをNSImageに変換。サイズも指定します。
                let image = NSImage(cgImage: cgImage, size: targetSize)
                
                // UIの更新はメインスレッドで行う必要があるため、メインスレッドにディスパッチ
                DispatchQueue.main.async {
                    // 生成した画像をキャッシュ用のディクショナリに保存
                    thumbnails[url] = image
                }
            }
        }
    }
}
