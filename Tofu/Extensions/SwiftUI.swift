import Foundation
import SwiftUI

extension ButtonStyle where Self == BigButtonStyle {
    static var primaryBigButton: BigButtonStyle { return BigButtonStyle(type: .primary) }
    static var secondaryBigButton: BigButtonStyle { return BigButtonStyle(type: .secondary) }
}

extension Color {

    static var systemBackground: Color {
        return Color(uiColor: .systemBackground)
    }

    static var dimmedSomething: Color {
        return Color(uiColor: .tertiarySystemFill)
    }
}

extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func onCondition<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Applies the given transform if the given condition evaluates to `true`, or another transform if not.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View` if the condition evaluates to `true`.
    ///   - elseTransform: The transform to apply to the source `View` if the condition evaluates to `false`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func onCondition<Content: View, ElseContent: View>(_ condition: Bool, transform: (Self) -> Content,
                                                                    else elseTransform: (Self) -> ElseContent) -> some View {
        if condition {
            transform(self)
        } else {
            elseTransform(self)
        }
    }

    /// Applies the given transform if the given optional isn't `nil`.
    /// - Parameters:
    ///   - value: The value to unwrap.
    ///   - transform: The transform to apply to the source `View` if the value can be unwrapped.
    @ViewBuilder func onUnwrap<Content: View, T>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
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
