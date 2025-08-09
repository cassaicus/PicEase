import SwiftUI

/// マウスのスクロールイベントを検知し、コールバックをトリガーするためのSwiftUIビュー。
/// `NSViewRepresentable`を使用してAppKitの`NSView`をラップし、`scrollWheel(with:)`イベントを取得します。
struct ScrollEventView: NSViewRepresentable {

    /// スクロールイベントが発生したときに呼び出されるコールバック。
    /// `CGFloat`パラメータは、y軸方向のスクロール移動量（`scrollingDeltaY`）です。
    var onScroll: (CGFloat) -> Void

    /// SwiftUIがこのビューの`NSView`インスタンスを作成する必要があるときに呼び出されます。
    func makeNSView(context: Context) -> NSView {
        // カスタムの`ScrollNSView`をインスタンス化します。
        let view = ScrollNSView()
        // コールバックを`ScrollNSView`のプロパティに設定します。
        view.onScroll = onScroll
        return view
    }

    /// `NSView`の状態を更新する必要があるときに呼び出されます。
    /// このビューでは状態の更新は不要なため、空実装です。
    func updateNSView(_ nsView: NSView, context: Context) {}

    /// スクロールイベントを捕捉するためのカスタム`NSView`サブクラス。
    class ScrollNSView: NSView {

        /// `ScrollEventView`から渡されるコールバッククロージャを保持します。
        var onScroll: ((CGFloat) -> Void)?

        /// このビューはマウスイベント（クリックなど）をブロックすべきではありません。
        /// `hitTest`で`nil`を返すことで、イベントがこのビューを「透過」し、
        /// 背後にある他のビューに到達するようにします。
        override func hitTest(_ point: NSPoint) -> NSView? {
            // スクロールイベントを受け取るために、このビューがヒット可能である必要がある。
            // `nil`を返すとイベントが透過してしまう。
            return self
        }

        /// マウスのスクロールホイールが操作されたときにシステムから呼び出されます。
        override func scrollWheel(with event: NSEvent) {
            // y軸のスクロール移動量（`scrollingDeltaY`）を使ってコールバックを呼び出します。
            // これにより、親のSwiftUIビューがスクロールの方向と強さを知ることができます。
            onScroll?(event.scrollingDeltaY)
        }
    }
}
