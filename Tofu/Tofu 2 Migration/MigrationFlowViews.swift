import Foundation
import SwiftUI

// MARK: - First Screen: Intro

@available(iOS 16.0, *)
struct MigrationIntroView: View {

    init(context: MigrationFlowStep.Context, completionHandler: @escaping (MigrationFlowStep.Action, MigrationFlowStep.Context) -> Void) {
        self.context = context
        self.completionHandler = completionHandler
        self.tofu2Installed = MigrationController.tofu2Installed
    }

    let context: MigrationFlowStep.Context
    let completionHandler: (MigrationFlowStep.Action, MigrationFlowStep.Context) -> Void

    private func cancelMigration() {
        completionHandler(.cancel, context)
    }

    private func cancelMigrationForever() {
        UserDefaults.standard.setValue(true, forKey: MigrationController.autoMigrationSilencedUserDefaultsKey)
        cancelMigration()
    }

    private func startMigration() {
        completionHandler(.confirm, context)
    }

    private func openInAppStore() {

    }

    private func openGitHubPage() {
        UIApplication.shared.open(URL(string: "https://github.com/iKenndac/Tofu")!)
    }

    private func updateTofu2Installed() {
        tofu2Installed = MigrationController.tofu2Installed
    }

    @State private var tofu2Installed: Bool

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .center) {
                VStack(alignment: .center, spacing: 20.0) {
                    Text(.legacyMigrationTitle)
                            .font(.system(size: 38.0, weight: .bold))
                            .lineLimit(2)
                            .minimumScaleFactor(0.5)

                    Text(.legacyMigrationWelcomeCommonBody)
                        .font(.system(size: 15.0))
                        .multilineTextAlignment(.center)

                    if !context.accounts.isEmpty {
                        Text(.legacyMigrationWelcomeWithAccountsBody(pluralizationCount: context.accounts.count,
                                                                     formatValue: "\(context.accounts.count)"))
                            .font(.system(size: 15.0))
                            .multilineTextAlignment(.center)
                    }

                    if !tofu2Installed {
                        Text(.legacyMigrationWelcomeTofu2NotInstalledBody)
                            .font(.system(size: 15.0))
                            .multilineTextAlignment(.center)
                    } else {
                        Text(.legacyMigrationWelcomeGetStartedBody)
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
                    Text(.viewOnAppStoreButtonTitle)
                }), secondaryButtons: [Button(action: openGitHubPage, label: {
                    Text(.viewOnGithubButtonTitle)
                })])
            } else {
                let finalButton: Button<Text> = {
                    if context.isAutomaticPresentation, context.previousDeferCount >= 5 {
                        return Button(action: cancelMigrationForever, label: { Text(.dontShowAgainButtonTitle) })
                    } else {
                        return Button(action: openGitHubPage, label: { Text(.viewOnGithubButtonTitle) })
                    }
                }()

                BottomSafeAreaButtons(primaryButton: Button(action: startMigration, label: {
                    Text(.beginMigrationButtonTitle)
                }).disabled(!tofu2Installed), secondaryButtons: [Button(action: cancelMigration, label: {
                    Text(.migrateLaterButtonTitle)
                }), finalButton]
                )
            }
        }
        .background(Color.systemBackground)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            updateTofu2Installed()
        }
    }
}

// MARK: - Second Screen: Collecting Encryption Passcode

@available(iOS 16.0, *)
struct MigrationPasscodeCollectionView: View {

    let context: MigrationFlowStep.Context
    let completionHandler: (MigrationFlowStep.Action, MigrationFlowStep.Context) -> Void

    @State private var passcode: String = ""

    private func commitPasscode(_ passcode: String) {
        guard passcode.count == context.passcodeDigitCount else { return }
        completionHandler(.confirm, context.withPasscode(passcode))
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .center) {
                VStack(alignment: .center, spacing: 20.0) {
                    Text(.legacyMigrationEnterPasscodeTitle)
                            .font(.system(size: 38.0, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)

                    Text(.legacyMigrationEnterPasscodeBody)
                        .font(.system(size: 15.0))
                        .multilineTextAlignment(.center)

                    PasscodeView(digitCount: context.passcodeDigitCount, passcode: $passcode)
                }
                .padding(.horizontal, 20.0)
                .padding(.top, 60.0)
                .padding(.bottom, 20.0)
                .frame(maxWidth: 450.0)
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color.systemBackground)
        .onChange(of: passcode) { commitPasscode($0) }
        .onDisappear { passcode = "" }
    }
}

// MARK: - Third Screen: Confirming Encryption Passcode

@available(iOS 16.0, *)
struct MigrationPasscodeConfirmationView: View {

    let context: MigrationFlowStep.Context
    let completionHandler: (MigrationFlowStep.Action, MigrationFlowStep.Context) -> Void

    @State private var passcode: String = ""
    @State private var failedAttempts: Int = 0

    private struct Shake: GeometryEffect {
        var amount: CGFloat = 10.0
        var shakesPerUnit: CGFloat = 3.0
        var animatableData: Int

        func effectValue(size: CGSize) -> ProjectionTransform {
            ProjectionTransform(CGAffineTransform(translationX:
                amount * sin(CGFloat(animatableData) * .pi * shakesPerUnit),
                y: 0))
        }
    }

    private func commitPasscode(_ passcode: String) {
        guard passcode.count == context.passcodeDigitCount else { return }
        guard passcode == context.passcode else {
            let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
            impactHeavy.impactOccurred()
            withAnimation(.default) { failedAttempts += 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.33, execute: { self.passcode = "" })
            return
        }

        completionHandler(.confirm, context)
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .center) {
                VStack(alignment: .center, spacing: 20.0) {
                    Text(.legacyMigrationConfirmPasscodeTitle)
                            .font(.system(size: 38.0, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)

                    Text(.legacyMigrationEnterPasscodeBody)
                        .font(.system(size: 15.0))
                        .multilineTextAlignment(.center)

                    PasscodeView(digitCount: context.passcodeDigitCount, passcode: $passcode)
                        .modifier(Shake(animatableData: failedAttempts))

                    if failedAttempts > 0 {
                        Text(.legacyMigrationPasscodesDifferentBody)
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
        .background(Color.systemBackground)
        .onChange(of: passcode) { commitPasscode($0) }
        .onDisappear { passcode = "" }
    }
}

// MARK: - Fourth Screen: Exporting

@available(iOS 16.0, *)
struct MigrationExportView: View {

    let context: MigrationFlowStep.Context
    let completionHandler: (MigrationFlowStep.Action, MigrationFlowStep.Context) -> Void

    @State private var didEncounterEncryptionFailure: Bool = false
    @State private var migrationData: Data? = nil
    @State private var exportingDocumentUrl: URL? = nil
    @State private var didEncounterExportFailure: Bool = false

    private func completeMigration() {
        completionHandler(.confirm, context)
    }

    private func cancelMigration() {
        completionHandler(.cancel, context)
    }

    private func exportDocument() {
        guard let migrationData else { return }
        do {
            let parent = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
            let fileUrl = parent.appending(path: "Tofu Account Migration Data.tofumigration", directoryHint: .notDirectory)
            try migrationData.write(to: fileUrl)
            exportingDocumentUrl = fileUrl
        } catch {
            didEncounterExportFailure = true
        }
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .center) {
                VStack(alignment: .center, spacing: 20.0) {
                    Text(.legacyMigrationReadyToMigrateTitle)
                        .font(.system(size: 38.0, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    Text(.legacyMigrationReadyToMigrateBody(pluralizationCount: context.accounts.count,
                                                            formatValue: "\(context.accounts.count)"))
                        .font(.system(size: 15.0))
                        .multilineTextAlignment(.center)

                    Text(.legacyMigrationInstructions)
                        .font(.system(size: 15.0))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20.0)
                .padding(.top, 60.0)
                .padding(.bottom, 20.0)
                .frame(maxWidth: 450.0)
            }
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
            BottomSafeAreaButtons(primaryButton: {
                Button(action: exportDocument, label: {
                    Text(.migrateAccountsButtonTitle(imageValue: Image(systemName: "arrow.up.doc"))) })
                .disabled(migrationData == nil)
                .background(content: {
                    // This is an anchor for the UIKit-world UIDocumentInteractionController.
                    OpenDocumentController(presentationUrl: $exportingDocumentUrl, completionHandler: completeMigration)
                })
            }(), secondaryButtons: [Button(action: cancelMigration, label: {
                Text(.migrateLaterButtonTitle)
            })])
        }
        .background(Color.systemBackground)
        .navigationBarBackButtonHidden()
        .alert(.legacyMigrationEncryptionFailedTitle, isPresented: $didEncounterEncryptionFailure, actions: {
            Button(role: .cancel, action: {}, label: { Text(.oKButtonTitle) })
        }, message: { Text(.legacyMigrationEncryptionFailedMessage) })
        .alert(.legacyMigrationDocumentHandlingFailedTitle, isPresented: $didEncounterExportFailure, actions: {
            Button(role: .cancel, action: {}, label: { Text(.oKButtonTitle) })
        }, message: { Text(.legacyMigrationDocumentHandlingFailedMessage) })
        .task {
            let accounts = context.accounts
            guard let passcode = context.passcode else {
                didEncounterEncryptionFailure = true
                return
            }
            DispatchQueue.global(qos: .userInitiated).async {
                let encrypter = ExternalDataInterop()
                do {
                    let encryptedAccounts = try encrypter.encryptedData(for: accounts, with: passcode)
                    DispatchQueue.main.async { self.migrationData = encryptedAccounts }
                } catch {
                    DispatchQueue.main.async { self.didEncounterEncryptionFailure = true }
                }
            }
        }
    }
}

// MARK: - Utility/Common

@available(iOS 16.0, *)
struct PasscodeView: View {

    init(digitCount: Int, passcode: Binding<String>) {
        self.digitCount = digitCount
        self.passcode = passcode
        self.internalPasscode = passcode.wrappedValue
    }

    let digitCount: Int
    let passcode: Binding<String>

    // This internalPasscode state will get everything entered into the text field, so having it separate
    // allows us to only expose filtered input back out to our external binding.
    @State private var internalPasscode: String
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            // PIN Dots
            HStack {
                Spacer()
                ForEach(0..<digitCount, id: \.self) { index in
                    Text(verbatim: dotSymbol(at: index))
                        .font(.system(size: 80.0, weight: .regular))
                        .frame(width: 36.0)
                    Spacer()
                }
            }

            // Hidden field to receive text
            TextField("", text: $internalPasscode)
                .multilineTextAlignment(.center)
                .accentColor(.clear)
                .foregroundColor(.clear)
                .keyboardType(.numberPad)
                .focused($focused)
                .opacity(0.05)
                .frame(height: 50.0)
                .onAppear { focused = true }
        }
        .onChange(of: internalPasscode) {
            // This happens when the textfield's text changes. We filter/validate, and push
            // values out to to the public binding.
            validatePasscode($0)
        }
        .onChange(of: passcode.wrappedValue) {
            // This happens when the external binding changes (i.e., maybe the client wants to clear the field).
            // We need to sync it to the internal binding.
            internalPasscode = $0
        }
    }

    private func dotSymbol(at index: Int) -> String {
        return index < passcode.wrappedValue.count ? "•" : "-"
    }

    // Even though we use the .numberPad keyboard, there are a number of ways to get non-digits into the text field.
    private let validDigits: String = "0123456789"

    private func validatePasscode(_ incomingPasscode: String) {
        var filteredPasscode = incomingPasscode.filter({ validDigits.contains($0) })
        if filteredPasscode.count > digitCount { filteredPasscode = String(filteredPasscode.prefix(digitCount)) }
        passcode.wrappedValue = filteredPasscode
        internalPasscode = filteredPasscode
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
