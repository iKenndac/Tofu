import Foundation

private enum KeychainEncodingVersion: UInt8 {
    case version1 = 1
    case version2 = 2
}

private func archivedDataForKeychainWithAccount(_ account: Account) throws -> Data {
    let data = try NSKeyedArchiver.archivedData(withRootObject: account, requiringSecureCoding: true)
    let version: UInt8 = KeychainEncodingVersion.version2.rawValue
    var versionedData = Data([version])
    versionedData.append(data)
    return versionedData
}

private func unarchiveAccountWithData(_ data: Data) -> Account? {
    guard !data.isEmpty else { return nil }
    guard let version = KeychainEncodingVersion(rawValue: data.first!) else { return nil }
    let encodedData = data.subdata(in: 1..<data.count)

    switch version {
    case .version1: return unarchiveV1AccountWithData(encodedData)
    case .version2: return try? NSKeyedUnarchiver.unarchivedObject(ofClass: Account.self, from: encodedData)
    }
}

private func unarchiveV1AccountWithData(_ data: Data) -> Account? {
    // This is here to decode accounts saved with Tofu >= 1.11. Since then, we've moved to a
    // slightly different encoding method (Accounts now conform to NSSecureCoding directly).
    guard let coder = try? NSKeyedUnarchiver(forReadingFrom: data),
          let secret = coder.decodeObject(of: NSData.self, forKey: "secret") as? Data,
          coder.containsValue(forKey: "algorithm"),
          let algorithm = Algorithm(rawValue: coder.decodeInt32(forKey: "algorithm")) else { return nil }

    let password = Password()
    password.algorithm = algorithm
    password.secret = secret
    password.digits = Int(coder.decodeInt32(forKey: "digits"))
    password.timeBased = coder.decodeBool(forKey: "timeBased")
    password.counter = Int(coder.decodeInt32(forKey: "counter"))
    password.period = Int(coder.decodeInt32(forKey: "period"))

    let account = Account()
    account.name = coder.decodeObject(of: NSString.self, forKey: "name") as? String
    account.issuer = coder.decodeObject(of: NSString.self, forKey: "issuer") as? String
    account.password = password
    return account
}

private func accountWithPersistentRef(_ persistentRef: Data) -> Account? {
    let query: [NSString: AnyObject] = [
        kSecClass: kSecClassGenericPassword,
        kSecValuePersistentRef: persistentRef as AnyObject,
        kSecReturnData: kCFBooleanTrue,
    ]
    var result: AnyObject?
    let code = SecItemCopyMatching(query as CFDictionary, &result)
    guard code == errSecSuccess,
        let data = result as? Data,
        let account = unarchiveAccountWithData(data) else { return nil }
    account.persistentRef = persistentRef
    return account
}

class Keychain: ObservableObject {
    func readAccounts() -> [Account] {
        let query: [NSString: AnyObject] = [
            kSecClass: kSecClassGenericPassword,
            kSecReturnPersistentRef: kCFBooleanTrue,
            kSecMatchLimit: kSecMatchLimitAll,
        ]
        var result: AnyObject?
        let code = SecItemCopyMatching(query as CFDictionary, &result)
        guard code == errSecSuccess, let persistentRefs = result as? [Data] else { return [] }
        return persistentRefs.compactMap { accountWithPersistentRef($0) }
    }

    func insertAccount(_ account: Account) -> Bool {
        guard let accountData = try? archivedDataForKeychainWithAccount(account) else { return false }
        let query: [NSString: AnyObject] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: ProcessInfo().globallyUniqueString as AnyObject,
            kSecAttrDescription: account.description as AnyObject,
            kSecValueData: accountData as AnyObject,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked,
            kSecReturnPersistentRef: true as AnyObject,
        ]
        var result: AnyObject?
        guard SecItemAdd(query as CFDictionary, &result) == errSecSuccess else { return false }
        account.persistentRef = (result as! Data)
        return true
    }

    func updateAccount(_ account: Account) -> Bool {
        guard let accountData = try? archivedDataForKeychainWithAccount(account) else { return false }
        let query: [NSString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecValuePersistentRef: account.persistentRef!
        ]
        let attributes: [NSString: AnyObject] = [
            kSecAttrDescription: account.description as AnyObject,
            kSecValueData: accountData as AnyObject,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked,
        ]
        return SecItemUpdate(query as CFDictionary, attributes as CFDictionary) == errSecSuccess
    }

    func deleteAccount(_ account: Account) -> Bool {
        let query: [NSString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecValuePersistentRef: account.persistentRef!
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}
