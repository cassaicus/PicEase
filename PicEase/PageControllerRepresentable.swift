import SwiftUI
import AppKit

struct PageControllerRepresentable: NSViewControllerRepresentable {
    @ObservedObject var controller: PageControllerWrapper

    func makeNSViewController(context: Context) -> NSPageController {
        let pageController = ImagePageController(controller: controller)
        return pageController
    }

    func updateNSViewController(_ nsViewController: NSPageController, context: Context) {
        let imagePaths = controller.imagePaths

        if imagePaths != nsViewController.arrangedObjects as? [URL] {
            nsViewController.arrangedObjects = imagePaths
        }

        guard !imagePaths.isEmpty else { return }

        if imagePaths.indices.contains(controller.selectedIndex) {
            nsViewController.selectedIndex = controller.selectedIndex
        } else {
            nsViewController.selectedIndex = 0
        }
    }
}
