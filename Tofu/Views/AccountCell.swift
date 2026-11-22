import UIKit

private func imageWithColor(_ color: UIColor, size: CGSize) -> UIImage {
    UIGraphicsBeginImageContext(size)
    color.setFill()
    UIRectFill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!;
}

private func formattedValue(_ value: String) -> String {
    let length = value.count
    let prefix = String(value.prefix(length / 2))
    let suffix = String(value.suffix(length - length / 2))
    return "\(prefix) \(suffix)"
}

class AccountCell: UITableViewCell {
    @IBOutlet weak var accountImageView: UIImageView!
    @IBOutlet weak var issuerLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var identifierLabel: UILabel!
    var delegate: AccountUpdateDelegate?
    private let button = UIButton(type: .custom)
    private let progressView = CircularProgressView()

    var account: Account! {
        didSet {
            accessoryView = account.password.timeBased ? progressView : button
            let now = Date()
            updateWithDate(now)
        }
    }

    override func awakeFromNib() {
        accountImageView.layer.cornerRadius = accountImageView.bounds.size.width / 4.5
        accountImageView.layer.cornerCurve = .continuous
        accountImageView.layer.masksToBounds = true
        accountImageView.layer.borderWidth = 1

        updateColors()

        valueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 44.0, weight: .thin)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        button.setTitle("NEXT", for: UIControl.State())
        button.setTitleColor(tintColor, for: UIControl.State())
        button.setTitleColor(UIColor.white, for: .highlighted)
        button.setTitleColor(UIColor.white, for: .selected)
        button.layer.borderColor = button.tintColor.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 4

        var config = UIButton.Configuration.plain()
        config.contentInsets = .init(top: 5.0, leading: 10.0, bottom: 5.0, trailing: 10.0)
        config.cornerStyle = .fixed
        button.configuration = config
        button.sizeToFit()

        let image = imageWithColor(tintColor, size: button.bounds.size)
        button.setBackgroundImage(image, for: .highlighted)
        button.setBackgroundImage(image, for: .selected)
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(didPressButton(_:)), for: .touchUpInside)
    }

    @objc func didPressButton(_ sender: UIButton) {
        account.password.counter += 1
        delegate?.updateAccount(account)
    }

    func updateWithDate(_ date: Date) {
        accountImageView.image = account.issuerImage
        issuerLabel.text = (account.description.first ?? "?").uppercased()
        issuerLabel.isHidden = accountImageView.image != nil
        valueLabel.text = formattedValue(account.password.valueForDate(date))
        identifierLabel.text = account.description
        progressView.progress = account.password.progressForDate(date)
        progressView.tintColor = account.password.timeIntervalRemainingForDate(date) < 5 ?
            .systemRed : tintColor
    }

    override func copy(_ sender: Any?) {
        guard let labelText = valueLabel.text else { return }

        UIPasteboard.general.string = labelText.replacingOccurrences(of: " ", with: "")
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle,
           let account = account {
            // When we change between light and dark mode, placeholder images need to be re-generated.
            accountImageView.image = account.issuerImage

            updateColors()
        }
    }

    private func updateColors() {
        if traitCollection.userInterfaceStyle == .dark {
            accountImageView.layer.backgroundColor = CGColor(red: 0.08, green: 0.08, blue: 0.1, alpha: 1)
            accountImageView.layer.borderColor = CGColor(red: 1, green: 1, blue: 1, alpha: 0.1)
        } else {
            accountImageView.layer.backgroundColor = CGColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1)
            accountImageView.layer.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0.1)
        }
    }
}
