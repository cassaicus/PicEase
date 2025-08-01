import SwiftUI
import AppKit

struct ContentView: NSViewControllerRepresentable {
    func makeNSViewController(context: Context) -> NSViewController {
        return ImagePageController()
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}
