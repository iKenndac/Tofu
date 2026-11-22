import Foundation
import SwiftUI
import Combine

fileprivate class AccountCellUpdateSignal {
    static let shared = AccountCellUpdateSignal()
    static let interval: TimeInterval = 0.5

    private var cancellables: [AnyCancellable] = []
    init() {
        Timer.publish(every: Self.interval, on: .main, in: .common)
            .autoconnect()
            .sink(receiveValue: { _ in self.publisher.send(Date()) })
            .store(in: &cancellables)
    }

    let publisher: PassthroughSubject<Date, Never> = .init()
}

// A basic string formatter that splits a string into to halves with a space.
fileprivate struct OTPCodeFormat: FormatStyle {
    func format(_ value: String) -> String {
        let length = value.count
        let prefix = String(value.prefix(length / 2))
        let suffix = String(value.suffix(length - length / 2))
        return "\(prefix) \(suffix)"
    }
}

fileprivate extension FormatStyle where Self == OTPCodeFormat {
    static var otp: OTPCodeFormat {
        return OTPCodeFormat()
    }
}

struct SUIAccountCell: View {

    private let iconSize: CGFloat = 64.0

    private let account: Account
    private let commitAccountChange: (Account) -> Void

    @State private var lastUpdatedDate: Date
    @State private var currentCode: String
    @State private var currentProgress: Double
    @State private var progressIsCritical: Bool

    init(account: Account, commitAccountChange: @escaping (Account) -> Void) {
        self.account = account
        self.commitAccountChange = commitAccountChange
        let now = Date()
        self.lastUpdatedDate = now
        self.currentCode = account.password.valueForDate(now)
        self.currentProgress = account.password.progressForDate(now)
        self.progressIsCritical = (account.password.timeIntervalRemainingForDate(now) < 5.0)
    }

    private var accountLabelText: String {
        let effectiveIssuer: String = account.issuer ?? ""
        let effectiveName: String = account.name ?? ""
        switch (effectiveIssuer.isEmpty, effectiveName.isEmpty) {
        case (false, false): return "\(effectiveIssuer) (\(effectiveName))"
        case (false, true): return effectiveIssuer
        case (true, false): return effectiveName
        case (true, true): return "—" // TODO: Localized better text
        }
    }

    private func updateCellContent() {
        let password = account.password.valueForDate(lastUpdatedDate)
        if password != currentCode { currentCode = password }
        let isCritical = (account.password.timeIntervalRemainingForDate(lastUpdatedDate) < 5.0)
        if isCritical != progressIsCritical { progressIsCritical = isCritical }
        // TODO: Don't animate on progress reset.
        currentProgress = account.password.progressForDate(lastUpdatedDate)
    }

    private func incrementHOTP() {
        account.password.counter += 1
        updateCellContent()
        commitAccountChange(account)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10.0) {
            if let image = account.issuerImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(.rect(cornerRadius: iconSize / 4.5, style: .continuous))
                    .overlay(content: { RoundedRectangle(cornerRadius: iconSize / 4.5)
                        .stroke(.quaternary, lineWidth: 0.5) })
            } else {
                ZStack(alignment: .center) {
                    Text(verbatim: account.issuer?.first?.uppercased() ?? "?")
                        .font(.system(size: 36.0, design: .rounded))
                        .foregroundStyle(.quaternary)
                }
                .frame(width: iconSize, height: iconSize)
                .background(.quaternary.opacity(0.2))
                .clipShape(.rect(cornerRadius: iconSize / 4.5, style: .continuous))
                .overlay(content: { RoundedRectangle(cornerRadius: iconSize / 4.5)
                    .stroke(.tertiary, lineWidth: 0.5) })
            }

            VStack(alignment: .leading, spacing: 0.0) {
                Text(currentCode, format: .otp)
                    .font(.largeTitle.monospacedDigit())
                    .lineLimit(1, reservesSpace: true)
                    .minimumScaleFactor(0.25)

                Text(verbatim: accountLabelText)
                    .font(.subheadline)
                    .bold()
                    .lineLimit(1, reservesSpace: true)
            }
            .frame(maxWidth: .infinity)

            if account.password.timeBased {
                SUICircularProgressView(progress: $currentProgress, isCritical: $progressIsCritical)
                    .frame(width: 28.0, height: 28.0)
            } else {
                Button(.nextHOTPButtonTitle, systemImage: "forward.end.circle", action: incrementHOTP)
                    .buttonStyle(.plain)
                    .font(.system(size: 30.0, weight: .light, design: .rounded))
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.blue)
                    .frame(width: 28.0, height: 28.0)
            }
        }
        .onReceive(AccountCellUpdateSignal.shared.publisher, perform: {
            lastUpdatedDate = $0
            updateCellContent()
        })
    }

}

fileprivate struct SUICircularProgressView: View {
    @Binding var progress: Double
    @Binding var isCritical: Bool

    private let lineWidth: CGFloat = 3.0

    private var color: Color {
        // TODO: Not sure we should animate colour
        if isCritical {
            return .red
        } else {
            return .blue
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: lineWidth)
                .opacity(0.1)
                .foregroundColor(color)

            Circle()
                .trim(from: 0.0, to: min(progress, 1.0))
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear(duration: AccountCellUpdateSignal.interval), value: progress)
        }
        .padding(lineWidth / 2.0) // To keep the stroke inside our frame.
    }
}

#Preview {

    let totpAccount = Account(url: URL(
        string: "otpauth://totp/Example:alice@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Example")!)!

    let hotpAccount = Account(url: URL(
        string: "otpauth://hotp/Example:alice@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Example&counter=1")!)!

    let commit: (Account) -> Void = {
        print("Committing account \($0.issuer ?? "?") with counter \($0.password.counter)")
    }

    List {
        SUIAccountCell(account: totpAccount, commitAccountChange: commit)
        SUIAccountCell(account: totpAccount, commitAccountChange: commit)
        SUIAccountCell(account: totpAccount, commitAccountChange: commit)
        SUIAccountCell(account: hotpAccount, commitAccountChange: commit)
    }
    .listStyle(.insetGrouped)
}
