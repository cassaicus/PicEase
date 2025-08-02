// SwiftUI フレームワークをインポート
import SwiftUI
// AppKit フレームワークをインポート（NSImage 等を利用）
import AppKit
// Combine フレームワークをインポート（非同期データストリームを扱う）
import Combine

// サムネイル画像を非同期に読み込んで公開するローダークラスを定義
class ThumbnailLoader: ObservableObject {
    // 読み込んだサムネイルを公開する Published プロパティ
    @Published var image: NSImage? = nil
    // 非同期読み込みをキャンセル可能にする AnyCancellable
    private var cancellable: AnyCancellable?
    // URL からサムネイルを読み込み、最大辺を maxSize にリサイズする
    func load(from url: URL, maxSize: CGFloat = 100) {
        // キャッシュに存在すれば即座に返して終了
        if let cached = ImageCache.shared.image(for: url) {
            self.image = cached
            return
        }
        // URL を Just パブリッシャーに流し込み、バックグラウンドで処理を実行
        cancellable = Just(url)
            // 読み込みはユーザー起因タスクとしてグローバルキューで実行
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            // URL から NSImage を生成し、リサイズ・キャッシュ登録を行う
            .map { url in
                // 画像生成に失敗したら nil を返却
                guard let img = NSImage(contentsOf: url) else { return nil }
                // 画像を maxSize に合わせてリサイズ
                let thumb = img.resized(toMax: maxSize)
                // リサイズ後のサムネイルをキャッシュに保存
                ImageCache.shared.setImage(thumb, for: url)
                return thumb
            }
            // 結果はメインスレッドで受け取る
            .receive(on: DispatchQueue.main)
            // 最終的な画像を Published プロパティに代入
            .sink { [weak self] img in
                self?.image = img
            }
    }
}

// サムネイルを表示する SwiftUI ビューを定義
struct ThumbnailImageView: View {
    // 表示対象の画像ファイル URL
    let url: URL
    // ThumbnailLoader を StateObject として保持
    @StateObject private var loader = ThumbnailLoader()
    // ビュー階層を定義
    var body: some View {
        // 読み込み中・完了時で分岐する Group
        Group {
            // 画像が読み込まれたら表示
            if let image = loader.image {
                Image(nsImage: image)
                    // 画像をリサイズ可能にする
                    .resizable()
                    // アスペクト比を維持してビューを埋める
                    .aspectRatio(contentMode: .fill)
            } else {
                // ロード中は薄いグレーのプレースホルダーを表示
                Color.gray.opacity(0.3)
            }
        }
        // ビューが出現したらサムネイル読み込みを開始
        .onAppear {
            loader.load(from: url)
        }
    }
}

