import AppKit

class ImageViewController: NSViewController {
    private var imageView = NSImageView()
    private var isZoomed = false // ズーム状態を管理

    override func loadView() {
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.wantsLayer = true
        imageView.canDrawSubviewsIntoLayer = true
        imageView.allowsCutCopyPaste = false
        imageView.isEditable = false
        imageView.imageAlignment = .alignCenter

        let containerView = NSView()
        containerView.addSubview(imageView)
        view = containerView

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        // ダブルクリックジェスチャー追加
        let doubleClick = NSClickGestureRecognizer(target: self, action: #selector(handleDoubleClick(_:)))
        doubleClick.numberOfClicksRequired = 2
        containerView.addGestureRecognizer(doubleClick)
    }

    func setImage(url: URL) {
        imageView.image = NSImage(contentsOf: url)
        resetZoom()
    }

    @objc private func handleDoubleClick(_ sender: NSClickGestureRecognizer) {
        toggleZoom()
    }

    private func toggleZoom() {
        guard let image = imageView.image else { return }

        isZoomed.toggle()

        if isZoomed {
            // ズームイン：実サイズの2倍で表示（縦横比維持）
            imageView.imageScaling = .scaleNone
            let size = image.size
            imageView.setFrameSize(NSSize(width: size.width * 2, height: size.height * 2))
        } else {
            // ズームアウト：ビューにフィット
            imageView.imageScaling = .scaleProportionallyUpOrDown
            imageView.setFrameSize(view.bounds.size)
        }
    }

    private func resetZoom() {
        isZoomed = false
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.setFrameSize(view.bounds.size)
    }
}
