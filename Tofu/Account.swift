import Foundation

class Account {
    var persistentRef: Data?
    var name: String?
    var issuer: String?
    var password = Password()

    convenience init?(url: URL) {
        let label = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let host = url.host, host == "hotp" || host == "totp" else { return nil }
        let labelComponents = label.components(separatedBy: ":")
        guard labelComponents.count > 0,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems,
            queryItems.count > 0
            else { return nil }

        self.init()

        name = labelComponents.last?.trimmingCharacters(in: CharacterSet.whitespaces)
        issuer = labelComponents.count > 1 ? labelComponents.first : nil
        password.timeBased = host == "totp"
        for queryItem in queryItems {
            switch queryItem.name {
            case "secret":
                guard let secretString = queryItem.value,
                    let secret = Data(base32Encoded: secretString)
                    else { break }
                password.secret = secret
            case "algorithm":
                switch queryItem.value {
                case .some("SHA256"): password.algorithm = .sha256
                case .some("SHA512"): password.algorithm = .sha512
                default: break
                }
            case "digits":
                guard let string = queryItem.value, let digits = Int(string) else { break }
                password.digits = digits
            case "issuer": issuer = queryItem.value
            case "counter":
                guard let string = queryItem.value, let counter = Int(string) else { break }
                password.counter = counter
            case "period":
                guard let string = queryItem.value, let period = Int(string) else { break }
                password.period = period
            default: break
            }
        }
        
        if password.secret.count == 0 || ![6, 8].contains(password.digits) { return nil }
    }

    var description: String {
        guard let issuer = issuer, issuer.count > 0 else { return name ?? "" }
        guard let name = name, name.count > 0 else { return issuer }
        return "\(issuer) (\(name))"
    }
}
