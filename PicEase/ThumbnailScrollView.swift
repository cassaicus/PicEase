// SwiftUI フレームワークをインポート
import SwiftUI

// サムネイルを横スクロールで表示するビューを定義
struct ThumbnailScrollView: View {
    // 表示する画像の URL 配列
    let imageURLs: [URL]
    // 現在選択中のインデックスを親ビューとバインディング
    @Binding var currentIndex: Int
    // ビューの本体を構築
    var body: some View {
        // スクロール位置をプログラム制御するリーダー
        ScrollViewReader { proxy in
            // 横方向スクロールビューを生成（インジケータ表示あり）
            ScrollView(.horizontal, showsIndicators: true) {
                // アイテムを水平に並べるスタック
                HStack {
                    // 配列をインデックス付きで列挙し、それぞれをビュー化
                    ForEach(Array(imageURLs.enumerated()), id: \.offset) { pair in
                        // 現在要素のインデックス
                        let index = pair.offset
                        // 現在要素の URL
                        let imageUrl = pair.element

                        // サムネイル表示用のカスタムビュー
                        ThumbnailImageView(url: imageUrl)
                            // 固定サイズを指定
                            .frame(width: 80, height: 80)
                            // はみ出し部分を切り落とす
                            .clipped()
                            // 選択中なら青い枠線、そうでなければ透明
                            .border(currentIndex == index ? Color.blue : Color.clear, width: 2)
                            // タップ時の処理を設定
                            .onTapGesture {
                                // 選択インデックスを更新
                                currentIndex = index
                                // 選択通知をポスト
                                NotificationCenter.default.post(name: .thumbnailSelected, object: index)
                            }
                            // スクロール制御用の一意 ID を設定
                            .id(index)
                    }
                }
                // 左右に余白を追加
                .padding(.horizontal)
            }
            // currentIndex が変化したときに中央へスクロール
            .onChange(of: currentIndex) { oldState, newIndex in
                withAnimation {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
            // 初回表示時に選択位置へスクロール
            .onAppear {
                DispatchQueue.main.async {
                    proxy.scrollTo(currentIndex, anchor: .center)
                }
            }
        }
    }
}

// 画像キャッシュを管理するシングルトンクラス
class ImageCache {
    // 共有インスタンス
    static let shared = ImageCache()
    // URL をキーに NSImage を保持する内部辞書
    private var cache: [URL: NSImage] = [:]
    // 外部からのインスタンス化を防ぐ
    private init() {}
    // キャッシュから画像を取得
    func image(for url: URL) -> NSImage? {
        return cache[url]
    }
    // キャッシュに画像を保存
    func setImage(_ image: NSImage, for url: URL) {
        cache[url] = image
    }
}

// ImageCache にサムネイル生成機能を拡張
extension ImageCache {
    // URL から最大辺が maxSize のサムネイルを返す
    func thumbnail(for url: URL, maxSize: CGFloat = 100) -> NSImage? {
        // キャッシュ済みサムネイルがあればそれを返す
        if let cached = cache[url] { return cached }
        // 元画像をロードできなければ nil を返す
        guard let image = NSImage(contentsOf: url) else { return nil }
        // リサイズしてサムネイルを生成
        let thumbnail = image.resized(toMax: maxSize)
        // キャッシュに保存
        cache[url] = thumbnail
        // 生成したサムネイルを返す
        return thumbnail
    }
}

// NSImage にリサイズ機能を追加する拡張
extension NSImage {
    // 画像を maxSize を超えないよう比率を保ってリサイズ
    func resized(toMax maxSize: CGFloat) -> NSImage {
        // 幅と高さの比率から縮小率を計算
        let ratio = min(maxSize / size.width, maxSize / size.height)
        // 新しいサイズを計算
        let newSize = NSSize(width: size.width * ratio, height: size.height * ratio)
        // 新しいサイズの空の NSImage を生成
        let newImage = NSImage(size: newSize)
        // 描画開始
        newImage.lockFocus()
        // 元画像を縮小して新しいサイズで描画
        draw(in: NSRect(origin: .zero, size: newSize),
             from: NSRect(origin: .zero, size: size),
             operation: .copy,
             fraction: 1.0)
        // 描画終了
        newImage.unlockFocus()
        // リサイズ後の画像を返す
        return newImage
    }
}
