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

struct ActivityViewController: UIViewControllerRepresentable {

    let activityItems: [Any]
    let completionHandler: (Bool, UIActivity.ActivityType?) -> Void

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: [])
        controller.completionWithItemsHandler = { type, completed, _, _ in
            completionHandler(completed, type)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}

}

struct OpenDocumentController: UIViewControllerRepresentable {

    let presentationUrl: Binding<URL?>

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

        func documentInteractionController(_ controller: UIDocumentInteractionController, 
                                           didEndSendingToApplication application: String?) {
            tidyUpDocumentInteractionState(success: true)
        }

        func documentInteractionControllerDidDismissOpenInMenu(_ controller: UIDocumentInteractionController) {
            // This doesn't mean failure. It seems impossible to tell with 100% reliability if a document open succeeded or not.
            tidyUpDocumentInteractionState(success: true)
        }

        private func tidyUpDocumentInteractionState(success: Bool) {
            if let url = owner.presentationUrl.wrappedValue {
                try? FileManager.default.removeItem(at: url)
            }
            owner.presentationUrl.wrappedValue = nil
            documentInteractionController = nil
        }
    }
}
