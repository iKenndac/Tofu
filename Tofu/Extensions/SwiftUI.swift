import Foundation
import SwiftUI

@available(iOS 16.0, *)
extension ButtonStyle where Self == BigButtonStyle {
    static var primaryBigButton: BigButtonStyle { return BigButtonStyle(type: .primary) }
    static var secondaryBigButton: BigButtonStyle { return BigButtonStyle(type: .secondary) }
}

@available(iOS 16.0, *)
extension Color {

    static var systemBackground: Color {
        return Color(uiColor: .systemBackground)
    }

    static var dimmedSomething: Color {
        return Color(uiColor: .tertiarySystemFill)
    }
}

struct OpenDocumentController: UIViewControllerRepresentable {

    let presentationUrl: Binding<URL?>
    let completionHandler: () -> Void

    func makeUIViewController(context: UIViewControllerRepresentableContext<OpenDocumentController>) -> UIViewController {
        return UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<OpenDocumentController>) {
        if let url = presentationUrl.wrappedValue, context.coordinator.documentInteractionController == nil {
            let controller = UIDocumentInteractionController(url: url)
            controller.delegate = context.coordinator
            context.coordinator.documentInteractionController = controller
            controller.presentOpenInMenu(from: uiViewController.view.bounds, in: uiViewController.view, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(owner: self)
    }

    // This acts as storage for and delegate to the UIDocumentInteractionController.
    final class Coordinator: NSObject, UIDocumentInteractionControllerDelegate {

        let owner: OpenDocumentController
        var documentInteractionController: UIDocumentInteractionController? = nil

        init(owner: OpenDocumentController) {
            self.owner = owner
        }

        func documentInteractionControllerDidDismissOpenInMenu(_ controller: UIDocumentInteractionController) {
            // This doesn't mean failure. It seems impossible to tell with 100% reliability if a document open succeeded
            // or not, so we just have to forward back that the interaction controller closed.
            tidyUpDocumentInteractionState(success: true)
        }

        private func tidyUpDocumentInteractionState(success: Bool) {
            if let url = owner.presentationUrl.wrappedValue {
                try? FileManager.default.removeItem(at: url)
            }
            owner.presentationUrl.wrappedValue = nil
            documentInteractionController = nil
            owner.completionHandler()
        }
    }
}
