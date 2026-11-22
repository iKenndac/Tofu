import Foundation
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
    "PayPal": "PayPal",
    "Philips Hue": "PhilipsHue",
    "Posteo": "Posteo",
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

extension Account {

    var issuerImage: UIImage? {
        if let issuer, let imageName = imageNames[CaseInsensitiveString(issuer)] {
            return UIImage(named: imageName)!
        }

        // Scanning Mailchimp's QR codes generates accounts without issuers and with names similar to this: username@us20.admin.mailchimp.com
        if let name, name.contains("admin.mailchimp.com") {
            return UIImage(named: "Mailchimp")!
        }

        return nil
    }
}
