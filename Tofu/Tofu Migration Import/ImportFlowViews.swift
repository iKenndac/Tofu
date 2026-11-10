import Foundation
import SwiftUI

// MARK: - First Screen: Confirming Encryption Passcode

struct ImportPasscodeEnteringView: View {

    let context: MigrationImportStep.Context
    let completionHandler: (MigrationImportStep.Action, MigrationImportStep.Context) -> Void

    private let dataInterop = ExternalDataInterop()

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
        do {
            let accounts = try dataInterop.decryptAccounts(from: context.encryptedImportAccounts, with: passcode)
            completionHandler(.confirm, context.withDecryptedAccounts(accounts))
        } catch {
            let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
            impactHeavy.impactOccurred()
            withAnimation(.default) { failedAttempts += 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.33, execute: { self.passcode = "" })
        }
    }

    private func cancel() {
        completionHandler(.cancel, context)
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .center) {
                VStack(alignment: .center, spacing: 20.0) {
                    Text(.migrationImportEnterPasscodeTitle)
                        .font(.system(size: 38.0, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    Text(.migrationImportEnterPasscodeBody)
                        .font(.system(size: 15.0))
                        .multilineTextAlignment(.center)

                    PasscodeView(digitCount: context.passcodeDigitCount, passcode: $passcode)
                        .modifier(Shake(animatableData: failedAttempts))

                    if failedAttempts > 0 {
                        Text(.migrationImportWrongPasscodeBody)
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
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if #available(iOS 26.0, *) {
                    Button(role: .cancel, action: cancel)
                } else {
                    Button(Localizable.cancelButtonTitle, systemImage: "xmark", action: cancel)
                }
            }
        }
    }
}

// MARK: - Second Screen: Import Confirmation

struct ImportConfirmationView: View {

    struct CandidateAccount: Equatable, Hashable, Identifiable {
        let account: Account
        let canImport: Bool

        var id: Account { return account }
    }

    let context: MigrationImportStep.Context
    let completionHandler: (MigrationImportStep.Action, MigrationImportStep.Context) -> Void

    @State private var candidateAccounts: [CandidateAccount] = []
    @State private var importableAccounts: [Account] = []

    func importAccounts() {
        completionHandler(.confirm, context.withAccountsToImport(importableAccounts))
    }

    func cancelImport() {
        completionHandler(.cancel, context)
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .center) {
                VStack(alignment: .center, spacing: 20.0) {
                    Text(.readyToImportAccountsTitle)
                        .font(.system(size: 38.0, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    if importableAccounts.isEmpty {
                        Text(.readyToImportNoImportableAccountsBody)
                            .font(.system(size: 15.0))
                            .multilineTextAlignment(.center)
                    } else {
                        Text(.readyToImportAccountsBody(pluralizationCount: importableAccounts.count,
                                                        formatValue: "\(importableAccounts.count)"))
                        .font(.system(size: 15.0))
                        .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 20.0) {
                        ForEach(Array(candidateAccounts.enumerated()), id: \.element) { index, account in
                            VStack(alignment: .leading, spacing: 4.0) {
                                Text(account.account.issuer ?? "—")
                                    .bold()
                                    .lineLimit(1, reservesSpace: true)
                                    .fixedSize()
                                Text(account.account.name ?? "—")
                                    .lineLimit(1, reservesSpace: true)
                                    .fixedSize()

                                if !account.canImport {
                                    Text("Won't be imported (already present).")
                                        .lineLimit(1, reservesSpace: true)
                                        .fixedSize()
                                        .foregroundStyle(.red)
                                }
                            }
                            .minimumScaleFactor(0.75)
                            .frame(maxWidth: .infinity, alignment: .leading)

                            if index < candidateAccounts.count - 1 {
                                Divider()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20.0)
                    .padding(.horizontal, 30.0)
                    .background(Color.dimmedSomething.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 20.0, style: .continuous))
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
                Button(action: importAccounts, label: {
                    Text(.importAccountsButtonTitle(imageValue: Image(systemName: "arrow.down.doc")))
                })
                .disabled(importableAccounts.isEmpty)
            }(), secondaryButtons: [Button(action: cancelImport, label: {
                Text(.cancelButtonTitle)
            })])
        }
        .background(Color.systemBackground)
        .navigationBarBackButtonHidden()
        .task {
            candidateAccounts = context.decryptedImportAccounts.map({ toImport in
                let exists = context.existingAccounts.contains(where: { $0 == toImport })
                return .init(account: toImport, canImport: !exists)
            })
            importableAccounts = candidateAccounts.filter({ $0.canImport }).map({ $0.account })
        }
    }
}

// MARK: - Utility/Common

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
