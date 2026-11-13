import Foundation
import SwiftUI
import Combine

class MigrationImportController {

    static func presentImport(from archiveData: Data, at url: URL, into accounts: [Account],
                              importedAccountDestination: AccountCreationDelegate,
                              presentingIn parentViewController: UIViewController, animated: Bool) {

        // The SwiftUI view needs a completion handler at init time, but we don't have the UIKit view controller at that
        // point. This is a reference point for the completion handler to capture so the SwiftUI view can dismiss it.
        weak var presentedMigrationFlowController: UIViewController? = nil
        let startStep = MigrationImportStep.collectPasscode(for: archiveData, existingAccounts: accounts)

        let flowCoordinator = FlowCoordinator<MigrationImportStep>(initialStep: startStep) { id, action, context in
            // We can get URLs from the Inbox directory. Those should be deleted when we're done with them.
            if url.isInAppInbox {
                try? FileManager.default.removeItem(at: url)
            }

            if action == .confirm && !context.accountsToImport.isEmpty {
                importedAccountDestination.createAccounts(context.accountsToImport)
            }

            presentedMigrationFlowController?.dismiss(animated: true)
        }

        let root = UIHostingController(rootView: flowCoordinator)
        root.modalPresentationStyle = .fullScreen
        presentedMigrationFlowController = root
        parentViewController.present(root, animated: animated)
    }
}

extension MigrationImportStep {

    /// The UI to collect the passcode for the encrypted data.
    static func collectPasscode(for archiveData: Data, existingAccounts: [Account]) -> MigrationImportStep {
        return MigrationImportStep(id: .collectPasscode) {
            ImportPasscodeEnteringView(context: .init(existingAccounts: existingAccounts,
                                                      encryptedImportAccounts: archiveData),
                                       completionHandler: $0)
        }
    }

    /// The UI to confirm what'll be imported.
    static func confirmImport(context: Context) -> MigrationImportStep {
        return MigrationImportStep(id: .confirmImport) {
            ImportConfirmationView(context: context, completionHandler: $0)
        }
    }

    /// Signal for dismissing the flow.
    static var dismiss: MigrationImportStep {
        return MigrationImportStep(id: .dismiss, representsDismissal: true, view: { _ in EmptyView() })
    }
}

struct MigrationImportStep: FlowCoordinatorStep {

    static func == (lhs: MigrationImportStep, rhs: MigrationImportStep) -> Bool {
        return lhs.representsDismissal == rhs.representsDismissal && lhs.id == rhs.id
    }

    static func nextStep(from stepId: Id, performing action: Action, with context: Context) -> MigrationImportStep {
        switch (stepId, action) {
        case (.collectPasscode, .confirm): return .confirmImport(context: context)
        case (.confirmImport, .confirm): return .dismiss
        case (.dismiss, _): return .dismiss
        case (_, .cancel): return .dismiss
        }
    }

    struct Context: Equatable, Hashable {
        init(existingAccounts: [Account], encryptedImportAccounts: Data, decryptedImportAccounts: [Account]? = nil,
             accountsToImport: [Account]? = nil) {
            self.existingAccounts = existingAccounts
            self.encryptedImportAccounts = encryptedImportAccounts
            self.decryptedImportAccounts = decryptedImportAccounts ?? []
            self.accountsToImport = accountsToImport ?? []
        }
        
        let existingAccounts: [Account]
        let passcodeDigitCount: Int = 6
        let encryptedImportAccounts: Data
        let decryptedImportAccounts: [Account]
        let accountsToImport: [Account]

        func withDecryptedAccounts(_ accounts: [Account]) -> Self {
            return Self(existingAccounts: existingAccounts, encryptedImportAccounts: encryptedImportAccounts,
                        decryptedImportAccounts: accounts)
        }

        func withAccountsToImport(_ accounts: [Account]) -> Self {
            return Self(existingAccounts: existingAccounts, encryptedImportAccounts: encryptedImportAccounts,
                        decryptedImportAccounts: decryptedImportAccounts, accountsToImport: accounts)
        }
    }

    enum Id: String {
        case collectPasscode
        case confirmImport
        case dismiss
    }

    enum Action {
        case cancel
        case confirm
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
