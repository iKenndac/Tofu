import Foundation
import CryptoKit
import CommonCrypto
import UniformTypeIdentifiers

class ExternalDataInterop {

    enum ExternalDataInteropError: Error {
        case invalidPasscode
        case invalidData
        case encryptionFailed
    }

    /// The UTType of the migration file.
    @available(iOS 16.0, *)
    static var migrationDocumentType: UTType {
        return UTType(exportedAs: "org.danielkennett.twofu.migration", conformingTo: .data)
    }

    /// Encrypt the given accounts with the given passcode. A random salt will be generated.
    func encryptedData(for accounts: [Account], with passcode: String) throws -> Data {
        let encodedAccounts = try NSKeyedArchiver.archivedData(withRootObject: accounts, requiringSecureCoding: true)
        let container = try EncryptedAccountContainer(encrypting: encodedAccounts,
                                                      with: .aesGCMWithSalted256BitSHAPBKDF2DerivedKey,
                                                      password: passcode)
        return try NSKeyedArchiver.archivedData(withRootObject: container, requiringSecureCoding: true)
    }

    /// Attempt to decrypt the given accounts with using the given passcode.
    func decryptAccounts(from encryptedAccountData: Data, with passcode: String) throws -> [Account] {

        guard let decodedContainer = try NSKeyedUnarchiver.unarchivedObject(ofClass: EncryptedAccountContainer.self,
                                                                            from: encryptedAccountData) else {
            throw ExternalDataInteropError.invalidData
        }

        let decryptedData = try decodedContainer.decryptedData(with: passcode)

        guard let accounts: [Account] = try {
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: decryptedData)
            unarchiver.requiresSecureCoding = true
            return unarchiver.decodeObject(of: [NSArray.self, Account.self], forKey: NSKeyedArchiveRootObjectKey) as? [Account]
        }() else {
            throw ExternalDataInteropError.invalidData
        }
        return accounts
    }

    /// This class encapsulates the encryption/decryption implementation details.
    @objc(EncryptedAccountContainer) private class EncryptedAccountContainer: NSObject, NSSecureCoding {

        static let supportsSecureCoding: Bool = true

        enum Algorithm: Int {
            // AES-GCM with a 256-bit encryption key derived with PBKDF2 with the SHA256 pseudo-random algorithm.
            case aesGCMWithSalted256BitSHAPBKDF2DerivedKey = 0
        }
        
        /// Initialise a container with the given unencrypted data. The data will be encrypted with the given algorithm
        /// using sensible defaults for it. If a salt is needed, it'll be randomly generated.
        init(encrypting unEncryptedData: Data, with algorithm: Algorithm, password: String) throws {

            // 600k figure from https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html#pbkdf2
            self.rounds = 600_000
            self.algorithm = algorithm

            let (u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16) = UUID().uuid
            let uuidArray = [u1,u2,u3,u4,u5,u6,u7,u8,u9,u10,u11,u12,u13,u14,u15,u16]
            self.salt = Data(uuidArray)

            super.init()
            let key = try encryptionKey(from: password, salt: salt, rounds: rounds)
            self.encryptedData = try AES.GCM.seal(unEncryptedData, using: key).combined!
        }

        required init?(coder: NSCoder) {
            let rounds = coder.decodeInteger(forKey: "rounds")
            guard rounds > 0, let salt = coder.decodeObject(of: NSData.self, forKey: "salt") as? Data,
                  let algorithm = Algorithm(rawValue: coder.decodeInteger(forKey: "algorithm")),
                  let encryptedData = coder.decodeObject(of: NSData.self, forKey: "payload") as? Data else {
                return nil
            }

            self.salt = salt
            self.rounds = rounds
            self.algorithm = algorithm
            self.encryptedData = encryptedData
        }

        let salt: Data
        let rounds: Int
        let algorithm: Algorithm
        private(set) var encryptedData: Data = Data()

        func encode(with coder: NSCoder) {
            coder.encode(salt, forKey: "salt")
            coder.encode(rounds, forKey: "rounds")
            coder.encode(algorithm.rawValue, forKey: "algorithm")
            coder.encode(encryptedData, forKey: "payload")
        }

        func decryptedData(with password: String) throws -> Data {
            let key = try encryptionKey(from: password, salt: salt, rounds: rounds)
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            return try AES.GCM.open(sealedBox, using: key)
        }

        /// Generate an encryption/decryption key for the given passcode.
        private func encryptionKey(from passcode: String, salt: Data, rounds: Int) throws -> SymmetricKey {
            guard !passcode.isEmpty else { throw ExternalDataInteropError.invalidPasscode }
            return SymmetricKey(data: try derivedPBKDF2Key(from: passcode, salt: salt, keySize: .bits256, rounds: rounds))
        }

        /// Generate a PBKDF2 derived key from the given password, salt, and rounds.
        private func derivedPBKDF2Key(from password: String, salt saltData: Data, keySize: SymmetricKeySize, rounds: Int) throws -> Data {

            // To perform PBKDF2 key derivation, we need to use CommonCrypto, which isn't very Swift-y.
            let passwordData = Data(password.utf8)
            let saltLength = saltData.count

            let derivedKeyByteLength = keySize.bitCount / 8
            var derivedKeyData = Data(repeating: 0, count: derivedKeyByteLength)

            let derivationStatus: Int32 = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
                saltData.withUnsafeBytes { saltBytes in
                    let keyBuffer: UnsafeMutablePointer<UInt8> = derivedKeyBytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
                    let saltBuffer: UnsafePointer<UInt8> = saltBytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
                    return CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2), password, passwordData.count, saltBuffer, saltLength,
                                                CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), UInt32(rounds),
                                                keyBuffer, derivedKeyByteLength)
                }
            }

            guard derivationStatus == kCCSuccess else { throw ExternalDataInteropError.encryptionFailed }
            return derivedKeyData
        }
    }
}
