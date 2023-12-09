import Foundation
import SwiftUI

@available(iOS 16.0, *)
struct MigrationIntroView: View {

    let context: MigrationFlowStep.Context
    let completionHandler: (MigrationFlowStep.Action, MigrationFlowStep.Context) -> Void

    func cancelMigration() {
        completionHandler(.cancel, context)
    }

    func startMigration() {
        completionHandler(.next, context)
    }

    func openInAppStore() {

    }

    func openGitHubPage() {
        UIApplication.shared.open(URL(string: "https://github.com/iKenndac/Tofu")!)
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .center) {
                VStack(alignment: .center, spacing: 20.0) {
                    Text(.legacyMigrationTitle, tableName: LegacyMigrationOut.tableName)
                            .font(.system(size: 38.0, weight: .bold, design: .rounded))
                            .lineLimit(2)
                            .minimumScaleFactor(0.5)

                    Text(.legacyMigrationWelcomeCommonBody, tableName: LegacyMigrationOut.tableName)
                        .font(.system(size: 15.0))
                        .multilineTextAlignment(.center)

                    if !context.accounts.isEmpty {
                        Text(.legacyMigrationWelcomeWithAccountsBody(pluralizationCount: context.accounts.count,
                                                                     formatValue: "\(context.accounts.count)"),
                             tableName: LegacyMigrationOut.tableName)
                            .font(.system(size: 15.0))
                            .multilineTextAlignment(.center)
                    }

                }
                .padding(.horizontal, 20.0)
                .padding(.top, 60.0)
                .padding(.bottom, 20.0)
                .frame(maxWidth: 450.0)
            }
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            if context.accounts.isEmpty {
                BottomSafeAreaButtons(primaryButton: Button(action: openInAppStore, label: {
                    Text(.viewOnAppStoreButtonTitle, tableName: LegacyMigrationOut.tableName)
                }), secondaryButtons: [Button(action: openGitHubPage, label: {
                    Text(.viewOnGithubButtonTitle, tableName: LegacyMigrationOut.tableName)
                })])
            } else {
                BottomSafeAreaButtons(primaryButton: Button(action: startMigration, label: {
                    Text(.beginMigrationButtonTitle, tableName: LegacyMigrationOut.tableName)
                }),
                                      secondaryButtons: [Button(action: cancelMigration, label: {
                    Text(.migrateLaterButtonTitle, tableName: LegacyMigrationOut.tableName)
                }), Button(action: openGitHubPage, label: {
                    Text(.viewOnGithubButtonTitle, tableName: LegacyMigrationOut.tableName)
                })]
                )
            }
        }
        .background(Color.systemBackground)
    }

}

@available(iOS 16.0, *)
struct BottomSafeAreaButtons<PrimaryButton: View, SecondaryButton: View>: View {

    let primaryButton: PrimaryButton
    let secondaryButtons: [SecondaryButton]

    var body: some View {
        VStack(spacing: 0.0) {
            Color.systemBackground
                .mask(LinearGradient(colors: [.white, .clear], startPoint: .bottom, endPoint: .top))
                .frame(height: 20.0)
            Color.systemBackground
                .frame(height: 10.0)

            ViewThatFits(in: .horizontal) {
                // Horizontal buttons for landscape iPhones.
                HStack(spacing: 10.0) {
                    ForEach(0..<secondaryButtons.count, id: \.self) {
                        secondaryButtons[$0].buttonStyle(.secondaryBigButton).frame(minWidth: 220.0)
                    }
                    primaryButton
                        .buttonStyle(.primaryBigButton)
                        .frame(minWidth: 220.0)
                }

                // Vertical buttons for everything else.
                VStack(spacing: 10.0) {
                    ForEach(0..<secondaryButtons.count, id: \.self) {
                        secondaryButtons[$0].buttonStyle(.secondaryBigButton)
                    }
                    primaryButton
                        .buttonStyle(.primaryBigButton)
                }
                .frame(maxWidth: 450.0)
            }
            .background(Color.systemBackground)

            Color.systemBackground
                .frame(height: 20.0)
                .background(Color.systemBackground) // This is needed to extend into the safe area
        }
        .padding(.horizontal, 20.0)
    }
}
