import AppKit

class ImageViewController: NSViewController {
    private var imageView = NSImageView()
    private var zoomScale: CGFloat = 1.0 // ズーム倍率（1.0, 2.0, 4.0）

    override func loadView() {
        let containerView = ZoomableImageViewContainer()
        containerView.wantsLayer = true

        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.wantsLayer = true
        imageView.imageAlignment = .alignCenter

        containerView.addSubview(imageView)
        view = containerView

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        let doubleClick = NSClickGestureRecognizer(target: self, action: #selector(handleDoubleClick(_:)))
        doubleClick.numberOfClicksRequired = 2
        containerView.addGestureRecognizer(doubleClick)

        // ズームイベントハンドラの接続
        containerView.onZoom = { [weak self] scaleDelta, location in
            self?.zoom(by: scaleDelta, at: location)
        }
        containerView.onPan = { [weak self] delta in
            self?.pan(by: delta)
        }

    }

    func setImage(url: URL) {
        imageView.image = NSImage(contentsOf: url)
        resetZoom()
    }
    
    private func pan(by delta: NSPoint) {
        guard zoomScale > 1.0,
              let layer = imageView.layer else { return }

        let current = layer.position
        let newPos = CGPoint(x: current.x + delta.x, y: current.y + delta.y)
        layer.position = newPos
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
    
    
    private func zoom(by scaleFactor: CGFloat, at point: CGPoint) {
        guard let layer = imageView.layer else { return }

        // 現在の拡大率に乗算（制限あり）
        zoomScale *= scaleFactor
        zoomScale = min(max(zoomScale, 0.1), 10.0)

        // アンカーポイントをズーム起点に
        let bounds = imageView.bounds
        let anchorX = point.x / bounds.width
        let anchorY = point.y / bounds.height
        layer.anchorPoint = CGPoint(x: anchorX, y: anchorY)
        layer.position = point

        applyTransform(iv: imageView)
    }

    
    
    
    
    class ZoomableImageViewContainer: NSView {
        var onZoom: ((CGFloat, CGPoint) -> Void)?
        var onPan: ((NSPoint) -> Void)?

        private var isDragging = false
        private var lastDragLocation: NSPoint?

        override func scrollWheel(with event: NSEvent) {
            if event.modifierFlags.contains(.command) {
                let delta = event.deltaY
                let zoomFactor = delta > 0 ? 1.1 : 0.9
                let location = convert(event.locationInWindow, from: nil)
                onZoom?(zoomFactor, location)
            } else {
                super.scrollWheel(with: event)
            }
        }

        override func magnify(with event: NSEvent) {
            let zoomFactor = 1.0 + event.magnification
            let location = convert(event.locationInWindow, from: nil)
            onZoom?(zoomFactor, location)
        }

        override func mouseDown(with event: NSEvent) {
            isDragging = true
            lastDragLocation = convert(event.locationInWindow, from: nil)
        }

        override func mouseDragged(with event: NSEvent) {
            guard isDragging, let lastLocation = lastDragLocation else { return }
            let currentLocation = convert(event.locationInWindow, from: nil)
            let delta = NSPoint(x: currentLocation.x - lastLocation.x,
                                y: currentLocation.y - lastLocation.y)
            onPan?(delta)
            lastDragLocation = currentLocation
        }

        override func mouseUp(with event: NSEvent) {
            isDragging = false
            lastDragLocation = nil
        }

        override var acceptsFirstResponder: Bool { true }
    }

}
