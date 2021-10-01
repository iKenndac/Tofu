import UIKit

private struct CaseInsensitiveString: Hashable, ExpressibleByStringLiteral {
    let value: String

    init(stringLiteral: String) {
        self.init(stringLiteral)
    }

    init(_ string: String) {
        self.value = string.lowercased()
    }
}

private let imageNames: [CaseInsensitiveString: String] = [
    "17th Shard": "17thShard",
    "Adobe ID": "Adobe",
    "Allegro": "Allegro",
    "Amazon Web Services": "AWS",
    "Amazon": "Amazon",
    "AnonAddy": "AnonAddy",
    "Aruba Instant On": "Aruba",
    "Atlassian": "Atlassian",
    "AWS": "AWS",
    "Backblaze": "Backblaze",
    "Basecamp's+Launchpad": "Basecamp",
    "Binance.com": "Binance",
    "BitBayAuth": "BitBay",
    "Bitbucket": "Bitbucket",
    "Bitstamp": "Bitstamp",
    "Bittrex": "Bittrex",
    "Bitwarden": "Bitwarden",
    "Cloudflare": "Cloudflare",
    "Coinbase": "Coinbase",
    "coned.okta.com": "ConEdison",
    "Contentful": "Contentful",
    "CorporateTrust": "CorporateTrust",
    "CyDIS": "CyDIS",
    "DigitalOcean": "DigitalOcean",
    "Discord": "Discord",
    "DNSimple": "DNSimple",
    "Dropbox": "Dropbox",
    "Electronic Arts": "ElectronicArts",
    "Epic+Games": "EpicGames",
    "Evernote": "Evernote",
    "Facebook": "Facebook",
    "Fastmail": "FastMail",
    "Fidelity": "Fidelity",
    "Figma": "Figma",
    "Firefox": "Firefox",
    "gandi.net": "Gandi",
    "Gitea": "Gitea",
    "GitHub": "GitHub",
    "gitlab.com": "GitLab",
    "GoDaddy": "GoDaddy",
    "Google": "Google",
    "GreenAddress": "GreenAddress",
    "Hack The Box": "HackTheBox",
    "Heroku": "Heroku",
    "Hetzner": "Hetzner",
    "HEY": "HEY",
    "Home Assistant": "HomeAssistant",
    "Honeybadger.io": "Honeybadger",
    "Hostek": "Hostek",
    "Hover": "Hover",
    "hub.docker.com": "Docker",
    "HumbleBundle": "HumbleBundle",
    "id.unity.com": "Unity",
    "IFTTT": "IFTTT",
    "ID.me": "IDme",
    "Instagram": "Instagram",
    "Intercom": "Intercom",
    "JetBrains+Account": "JetBrains",
    "Kickstarter": "Kickstarter",
    "LastPass": "LastPass",
    "LinkedIn": "LinkedIn",
    "LinodeManager": "Linode",
    "Lobsters": "Lobsters",
    "LocalBitcoins": "LocalBitcoins",
    "Mastodon": "Mastodon",
    "Mailchimp": "Mailchimp",
    "Mega": "Mega",
    "Microsoft": "Microsoft",
    "Name.com": "Name.com",
    "Netlify": "Netlify",
    "Nextcloud": "Nextcloud",
    "Nexus Mods": "NexusMods",
    "NiceHash - New platform": "NiceHash",
    "NiceHash": "NiceHash",
    "Nintendo Account": "Nintendo",
    "Njalla": "Njalla",
    "Nodecraft Inc": "Nodecraft",
    "NordPass": "NordPass",
    "ownCloud": "ownCloud",
    "Paladin Extensions": "PaladinExtensions",
    "Parler": "Parler",
    "Parsec": "Parsec",
    "PayPal": "PayPal",
    "Philips Hue": "PhilipsHue",
    "Postmark": "Postmark",
    "Privacy.com": "Privacy",
    "ProfitBricks": "ProfitBricks",
    "ProtonMail": "ProtonMail",
    "PrusaAccount": "PrusaAccount",
    "Reddit": "Reddit",
    "Robinhood": "Robinhood",
    "rubygems.org": "RubyGems",
    "RuneScape": "RuneScape",
    "SimpleLogin": "SimpleLogin",
    "Slack": "Slack",
    "Snapchat": "Snapchat",
    "Sony": "Sony",
    "Squarespace": "Squarespace",
    "STACK": "STACK",
    "Standard Notes": "StandardNotes",
    "Stripe": "Stripe",
    "Surfshark": "Surfshark",
    "TETR.IO": "TETR.IO",
    "Time4VPS": "Time4VPS",
    "TorGuard": "TorGuard",
    "Tresorit": "Tresorit",
    "Tumblr": "Tumblr",
    "TurboTax": "TurboTax",
    "Tutanota": "Tutanota",
    "Tweakers": "Tweakers",
    "Twilio": "Twilio",
    "Twitch": "Twitch",
    "Twitter": "Twitter",
    "Uber": "Uber",
    "Ubisoft": "Ubisoft",
    "VKontakte": "VKontakte",
    "Wallabag": "Wallabag",
    "WordPress": "WordPress",
    "WordPress.com": "WordPress",
    "YNAB": "YNAB",
    "Zoom": "Zoom",
]

private func image(for account: Account) -> UIImage? {
    if let issuer = account.issuer,
       let imageName = imageNames[CaseInsensitiveString(issuer)] {
        return UIImage(named: imageName)!
    }

    // Scanning Mailchimp's QR codes generates accounts without issuers and with names similar to this: username@us20.admin.mailchimp.com
    if let name = account.name,
       name.contains("admin.mailchimp.com") {
        return UIImage(named: "Mailchimp")!
    }

    return nil
}

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

        let featureSettings: [[UIFontDescriptor.FeatureKey: Any]] =
            [[.featureIdentifier: kNumberSpacingType, .typeIdentifier: kMonospacedNumbersSelector]]
        let fontDescriptor = valueLabel.font.fontDescriptor.addingAttributes([.featureSettings: featureSettings])
        valueLabel.font = UIFont(descriptor: fontDescriptor, size: 0)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        button.setTitle("NEXT", for: UIControl.State())
        button.setTitleColor(tintColor, for: UIControl.State())
        button.setTitleColor(UIColor.white, for: .highlighted)
        button.setTitleColor(UIColor.white, for: .selected)
        button.layer.borderColor = button.tintColor.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 4
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
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
        accountImageView.image = Tofu.image(for: account)
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
            accountImageView.image = Tofu.image(for: account)

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
