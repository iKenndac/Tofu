import Foundation
import SwiftUI

class MigrationController {

    static var supportsMigration: Bool {
        if #available(iOS 16.0, *) { return true }
        return false
    }

    static var shouldAutoPresentMigration: Bool {
        // TODO: Check "don't show again" flag
        // TODO: Only return `true` once per session.
        return supportsMigration
    }

    static func presentMigration(of accounts: [Account], in parentViewController: UIViewController, animated: Bool) {
        guard #available(iOS 16.0, *) else { return }

        // The SwiftUI view needs a completion handler at init time, but we don't have the UIKit view controller at that
        // point. This is a reference point for the completion handler to capture so the SwiftUI view can dismiss it.
        weak var presentedMigrationFlowController: UIViewController? = nil

        let flowCoordinator = FlowCoordinator<MigrationFlowStep>(initialStep: .intro(with: accounts)) { id, action, context in
            // TODO: On cancel, increment counter and show "Don't Show Again" button after x dismisses.
            presentedMigrationFlowController?.dismiss(animated: true)
        }

        let root = UIHostingController(rootView: flowCoordinator)
        root.modalPresentationStyle = .fullScreen
        presentedMigrationFlowController = root
        parentViewController.present(root, animated: animated)
    }

}

@available(iOS 16.0, *)
extension MigrationFlowStep {

    /// The intro screen, explaining what happened and the need to download the new app.
    static func intro(with accounts: [Account]) -> MigrationFlowStep {
        return MigrationFlowStep(id: .intro) {
            MigrationIntroView(context: .init(accounts: accounts, passcode: nil), completionHandler: $0)
        }
    }
    
    /// Signal for dismissing the flow.
    static var dismiss: MigrationFlowStep {
        return MigrationFlowStep(id: .dismiss, representsDismissal: true, view: { _ in EmptyView() })
    }
}


@available(iOS 16.0, *)
struct MigrationFlowStep: FlowCoordinatorStep {

    static func == (lhs: MigrationFlowStep, rhs: MigrationFlowStep) -> Bool {
        return lhs.representsDismissal == rhs.representsDismissal && lhs.id == rhs.id
    }

    static func nextStep(from stepId: Id, performing action: Action, with context: Context) -> MigrationFlowStep {
        return .dismiss
    }

    struct Context: Equatable, Hashable {
        let accounts: [Account]
        let passcode: String?
    }

    enum Id: String {
        case intro
        case dismiss
    }

    enum Action {
        case cancel
        case next
    }

    init(id: Id, representsDismissal: Bool = false, view: @escaping (@escaping (Action, Context) -> Void) -> some View)  {
        self.id = id
        self.view = { AnyView(view($0)) }
        self.representsDismissal = representsDismissal
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(representsDismissal)
    }

    let id: Id
    let representsDismissal: Bool
    @ViewBuilder let view: (@escaping (Action, Context) -> Void) -> AnyView
}
