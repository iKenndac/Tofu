import Foundation

@objc(Account) class Account: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool { return true }

    /// This is a "pointer" to the account in the Keychain, and is set upon encode to/decode from such. It's not
    /// included in serialisation or equality checks, since it's not required for exporting to/importing from from
    /// elsewhere, and isn't useful for duplicate checking etc.
    var persistentRef: Data?
    var name: String?
    var issuer: String?
    var password = Password()
    let uniqueId: UUID

    override init() {
        uniqueId = UUID()
    }

    init?(url: URL, uniqueIdOverride: UUID? = nil) {
        let label = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let host = url.host, host == "hotp" || host == "totp" else { return nil }
        let labelComponents = label.components(separatedBy: ":")
        guard labelComponents.count > 0,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems,
            queryItems.count > 0
            else { return nil }

        name = labelComponents.last?.trimmingCharacters(in: CharacterSet.whitespaces)
        issuer = labelComponents.count > 1 ? labelComponents.first : nil
        uniqueId = (uniqueIdOverride ?? UUID())
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
                if digits < 6 || digits > 9 { return nil }
                password.digits = digits
            case "issuer": issuer = queryItem.value
            case "counter":
                guard let string = queryItem.value, let counter = Int(string) else { break }
                password.counter = counter
            case "period":
                guard let string = queryItem.value, let period = Int(string) else { break }
                if period < 1 { return nil }
                password.period = period
            default: break
            }
        }
        if password.secret.count == 0 { return nil }
    }

    required init?(coder: NSCoder) {
        guard let secret = coder.decodeObject(of: NSData.self, forKey: "secret") as? Data else { return nil }
        guard coder.containsValue(forKey: "algorithm") else { return nil }
        guard let algorithm = Algorithm(rawValue: coder.decodeInt32(forKey: "algorithm")) else { return nil }
        password.algorithm = algorithm
        password.secret = secret
        password.digits = Int(coder.decodeInt32(forKey: "digits"))
        password.timeBased = coder.decodeBool(forKey: "timeBased")
        password.counter = Int(coder.decodeInt32(forKey: "counter"))
        password.period = Int(coder.decodeInt32(forKey: "period"))

        name = coder.decodeObject(of: NSString.self, forKey: "name") as? String
        issuer = coder.decodeObject(of: NSString.self, forKey: "issuer") as? String
        uniqueId = (coder.decodeObject(of: NSUUID.self, forKey: "uuid") as? UUID) ?? UUID()
        // ^ Added in Tofu 2.1, transparent addition is fine.
    }

    func encode(with coder: NSCoder) {
        coder.encode(password.timeBased, forKey: "timeBased")
        coder.encode(password.algorithm.rawValue, forKey: "algorithm")
        coder.encode(Int32(password.digits), forKey: "digits")
        coder.encode(password.secret, forKey: "secret")
        coder.encode(Int32(password.counter), forKey: "counter")
        coder.encode(Int32(password.period), forKey: "period")
        coder.encode(name, forKey: "name")
        coder.encode(issuer, forKey: "issuer")
        coder.encode(uniqueId, forKey: "uuid")
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Account else { return false }
        return name == other.name && issuer == other.issuer && password == other.password
    }

    override var hash: Int { 
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(issuer)
        hasher.combine(password)
        return hasher.finalize()
    }

    override var description: String {
        guard let issuer = issuer, issuer.count > 0 else { return name ?? "" }
        guard let name = name, name.count > 0 else { return issuer }
        return "\(issuer) (\(name))"
    }
}
