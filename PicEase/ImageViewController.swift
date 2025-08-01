import AppKit

class ImageViewController: NSViewController {
    private var imageView = NSImageView()
    private var zoomScale: CGFloat = 1.0 // ズーム倍率（1.0, 2.0, 4.0）

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
        let location = sender.location(in: imageView)
        setZoomCenter(at: location)
        cycleZoom()
    }
    
    private func setZoomCenter(at point: CGPoint) {
        guard let layer = imageView.layer else { return }

        let bounds = imageView.bounds
        let anchorX = point.x / bounds.width
        let anchorY = point.y / bounds.height

        // ズーム中心をマウス位置に
        layer.anchorPoint = CGPoint(x: anchorX, y: anchorY)
        layer.position = point
    }
 
    private func cycleZoom() {
        guard let image = imageView.image, let layer = imageView.layer else { return }

        switch zoomScale {
        case ..<1.5:
            zoomScale = 2.0
        case ..<3.5:
            zoomScale = 4.0
        default:
            zoomScale = 1.0
            // リセット時に中心へ戻す
            layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            layer.position = CGPoint(x: imageView.bounds.midX, y: imageView.bounds.midY)
        }
        applyTransform(iv: imageView)
    }
    
    private func applyTransform(iv: NSImageView) {
         let scale = zoomScale
         iv.layer?.setAffineTransform(CGAffineTransform(scaleX: scale, y: scale))
     }


    private func resetZoom() {
        zoomScale = 1.0
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.setFrameSize(view.bounds.size)
    }
}
