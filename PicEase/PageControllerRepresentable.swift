import SwiftUI
import AppKit

struct PageControllerRepresentable: NSViewControllerRepresentable {
    @ObservedObject var controller: PageControllerWrapper
    let coordinator: Coordinator

    class Coordinator {
        var pageController: ImagePageController?

        func makeFirstResponder() {
            DispatchQueue.main.async {
                self.pageController?.view.window?.makeFirstResponder(self.pageController)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSViewController(context: Context) -> NSPageController {
        let pc = ImagePageController(controller: controller)
        context.coordinator.pageController = pc
        return pc
    }

    func updateNSViewController(_ nsViewController: NSPageController, context: Context) {
        let imagePaths = controller.imagePaths
        if imagePaths != nsViewController.arrangedObjects as? [URL] {
            nsViewController.arrangedObjects = imagePaths
        }

        if imagePaths.indices.contains(controller.selectedIndex) {
            nsViewController.selectedIndex = controller.selectedIndex
        }
    }

    // 外部から responder を復帰する用
    func makeFirstResponder(_ coordinator: Coordinator) {
        coordinator.makeFirstResponder()
    }
}
