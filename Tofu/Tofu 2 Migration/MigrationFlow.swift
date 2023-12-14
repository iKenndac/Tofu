import Foundation
import SwiftUI
import Combine

class MigrationController {

    static let hasMigratedUserDefaultsKey: String = "LegacyMigrationCompleted"
    static let migrationDeferredCountUserDefaultsKey: String = "LegacyMigrationDeferredCount"
    static let autoMigrationSilencedUserDefaultsKey: String = "LegacyMigrationSilenced"

    static var supportsMigration: Bool {
        if #available(iOS 16.0, *) { return true }
        return false
    }

    private (set) static var hasPresentedMigrationThisSession: Bool = false

    static var shouldAutoPresentMigration: Bool {
        let defaults = UserDefaults.standard
        return supportsMigration && !hasPresentedMigrationThisSession &&
            !defaults.bool(forKey: autoMigrationSilencedUserDefaultsKey) &&
            !defaults.bool(forKey: hasMigratedUserDefaultsKey)
    }

    static var tofu2Installed: Bool {
        return UIApplication.shared.canOpenURL(URL(string: "tofu2-migrate:")!)
    }

    private static var cancellables: Set<AnyCancellable> = []

    static func presentMigration(of accounts: [Account], in parentViewController: UIViewController, animated: Bool,
                                 isAutomaticPresentation: Bool) {
        guard #available(iOS 16.0, *) else { return }

        // The SwiftUI view needs a completion handler at init time, but we don't have the UIKit view controller at that
        // point. This is a reference point for the completion handler to capture so the SwiftUI view can dismiss it.
        weak var presentedMigrationFlowController: UIViewController? = nil
        let deferCount = UserDefaults.standard.integer(forKey: migrationDeferredCountUserDefaultsKey)

        let startStep = MigrationFlowStep.intro(with: accounts, previousDeferCount: deferCount,
                                                isAutomaticPresentation: isAutomaticPresentation)

        let flowCoordinator = FlowCoordinator<MigrationFlowStep>(initialStep: startStep) { id, action, context in
            let defaults = UserDefaults.standard
                switch action {
                case .confirm: 
                    defaults.set(true, forKey: hasMigratedUserDefaultsKey)
                case .cancel:
                    if isAutomaticPresentation {
                        defaults.setValue(deferCount + 1, forKey: migrationDeferredCountUserDefaultsKey)
                    }
                }

            cancellables.removeAll()
            NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification).sink { _ in
                hasPresentedMigrationThisSession = false
                cancellables.removeAll()
            }.store(in: &cancellables)
            hasPresentedMigrationThisSession = true
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
    static func intro(with accounts: [Account], previousDeferCount: Int, isAutomaticPresentation: Bool) -> MigrationFlowStep {
        return MigrationFlowStep(id: .intro) {
            MigrationIntroView(context: .init(isAutomaticPresentation: isAutomaticPresentation,
                                              previousDeferCount: previousDeferCount, accounts: accounts,
                                              passcodeDigitCount: 6, passcode: nil), completionHandler: $0)
        }
    }

    /// The screen to collect the passcode.
    static func collectPasscode(context: MigrationFlowStep.Context) -> MigrationFlowStep {
        return MigrationFlowStep(id: .collectPasscode, view: {
            MigrationPasscodeCollectionView(context: context, completionHandler: $0)
        })
    }

    /// The screen to confirm the passcode.
    static func confirmPasscode(context: MigrationFlowStep.Context) -> MigrationFlowStep {
        return MigrationFlowStep(id: .confirmPasscode, view: {
            MigrationPasscodeConfirmationView(context: context, completionHandler: $0)
        })
    }

    /// The screen to export the encrypted data.
    static func export(context: MigrationFlowStep.Context) -> MigrationFlowStep {
        return MigrationFlowStep(id: .export, view: {
            MigrationExportView(context: context, completionHandler: $0)
        })
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
        switch (stepId, action) {
        case (.intro, .confirm): return .collectPasscode(context: context)
        case (.collectPasscode, .confirm): return .confirmPasscode(context: context)
        case (.confirmPasscode, .confirm): return .export(context: context)
        case (.export, _): return .dismiss
        case (.dismiss, _): return .dismiss
        case (_, .cancel): return .dismiss
        }
    }

    struct Context: Equatable, Hashable {
        let isAutomaticPresentation: Bool
        let previousDeferCount: Int
        let accounts: [Account]
        let passcodeDigitCount: Int
        let passcode: String?

        func withPasscode(_ passcode: String) -> Self {
            return Self(isAutomaticPresentation: isAutomaticPresentation, previousDeferCount: previousDeferCount,
                        accounts: accounts, passcodeDigitCount: passcodeDigitCount, passcode: passcode)
        }
    }

    enum Id: String {
        case intro
        case collectPasscode
        case confirmPasscode
        case export
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
