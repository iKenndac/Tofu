import Foundation
import SwiftUI

/// Definitions of steps for the flow coordinator.
protocol FlowCoordinatorStep: Equatable, Hashable {
    /// A unique ID representing individual steps.
    associatedtype Id: Equatable, Hashable
    /// A type defining actions (continue, cancel, etc) that steps can perform.
    associatedtype CompletionAction: Equatable, Hashable
    /// A type defining a context object that'll be passed between steps.
    associatedtype Context: Equatable, Hashable
    
    /// Static function that's called when a flow controller needs a next step to show.
    ///
    /// - Parameters:
    ///   - stepId: The ID of the step that triggered the action.
    ///   - action: The action the step performed.
    ///   - context: The context the step produced while performing the action.
    ///
    /// - Returns: Returns the next step.
    static func nextStep(from stepId: Self.Id, performing action: Self.CompletionAction, with context: Context) -> Self

    /// A step's ID.
    var id: Id { get }

    /// Returns `true` if the step represents the dismissal of a flow, otherwise `false`.
    var representsDismissal: Bool { get }
    
    /// A view builder that constructs the UI for the step. Note that if the step returns `true` for
    /// `representsDismissal`, this will never be called. Such steps should return an `EmptyView`.
    @ViewBuilder var view: (@escaping (CompletionAction, Context) -> Void) -> AnyView { get }
}

/// A view for presenting and managing a "flow", which is a series of steps represented as views. Useful for onboardings,
/// migrations, etc.
@available(iOS 16.0, *) struct FlowCoordinator<Step: FlowCoordinatorStep>: View {
    
    /// Initialise a new `FlowCoordinator`.
    ///
    /// - Parameters:
    ///   - initialStep: The first step to show in the flow.
    ///   - completionHandler: A completion handler to be called when the flow encounters a step with
    ///                        `representsDismissal` set to `true`.
    init(initialStep: Step, completionHandler: @escaping (Step.Id, Step.CompletionAction, Step.Context) -> Void) {
        self.initialStep = initialStep
        self.completionHandler = completionHandler
    }

    let initialStep: Step
    let completionHandler: (Step.Id, Step.CompletionAction, Step.Context) -> Void

    // MARK: - Logic

    private func handleStepCompletionAction(_ action: Step.CompletionAction, from stepId: Step.Id, completionContext: Step.Context) {
        let nextStep = Step.nextStep(from: stepId, performing: action, with: completionContext)

        guard !nextStep.representsDismissal else {
            completionHandler(nextStep.id, action, completionContext)
            return
        }

        flowPath.append(nextStep)
    }

    // MARK: - View & Navigation

    @State private var flowPath: [Step] = []

    var body: some View {
        NavigationStack(path: $flowPath, root: {
            let step = initialStep
            step.view { action, context in
                handleStepCompletionAction(action, from: step.id, completionContext: context)
            }
            .navigationDestination(for: Step.self) { step in
                step.view({ handleStepCompletionAction($0, from: step.id, completionContext: $1) })
            }
        })
    }
}

