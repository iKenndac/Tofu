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
