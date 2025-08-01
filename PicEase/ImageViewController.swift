import AppKit

class ImageViewController: NSViewController {
    private var imageView = NSImageView() // 画像表示用ビュー

    override func loadView() {
        imageView.imageScaling = .scaleProportionallyUpOrDown // 比率維持
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.wantsLayer = true
        view = NSView()
        view.addSubview(imageView)

        // imageViewを全面に配置
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // 画像ファイルを読み込む
    func setImage(url: URL) {
        imageView.image = NSImage(contentsOf: url)
    }
}
