import Foundation
import SwiftUI

struct UserDefaultsKey {
    static let manualSortOrder: String = "ManualSortOrder"
}

// This is the base of the Tofu window. It's the truth of various pieces of data.
struct MainScene: View {

    @State private var accounts: [Account]
    private let keychain: Keychain = .init()

    init() {
        let totpAccount = Account(url: URL(
            string: "otpauth://totp/Example:alice@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Example")!, uniqueIdOverride: UUID(uuidString: "C537A7A6-138A-490D-BA64-3E7BDA36064C")!)!

        let hotpAccount = Account(url: URL(
            string: "otpauth://hotp/Amazon:alice@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Amazon&counter=1")!, uniqueIdOverride: UUID(uuidString: "DD5C90DD-227D-41B8-9EAD-9E56A03F84EB")!)!

        // TODO: Check if the old key is present, convert it, then serialise into the new value.
        // Note that if we *just* launched the new version, the UUIDs won't be persisted to the keychain yet.
        let sortedUUIDs: [UUID] = ((UserDefaults.standard.value(forKey: UserDefaultsKey.manualSortOrder) as? [String]) ?? [])
            .compactMap({ UUID(uuidString: $0) })
        let loadedAccounts = [totpAccount, hotpAccount]
        var loadedAccountsByUUID: [UUID: Account] = loadedAccounts.reduce(into: [:], { $0[$1.uniqueId] = $1 })
        var sortedAccounts: [Account] = []

        for uuid in sortedUUIDs {
            if let matchingAccount = loadedAccountsByUUID[uuid] {
                loadedAccountsByUUID.removeValue(forKey: uuid)
                sortedAccounts.append(matchingAccount)
            }
        }

        sortedAccounts.append(contentsOf: loadedAccountsByUUID.values)
        _accounts = .init(initialValue: sortedAccounts)
        persistManualSortOrder(of: sortedAccounts)
    }

    private func persistManualSortOrder(of accounts: [Account]) {
        let manualOrder: [String] = accounts.map({ $0.uniqueId.uuidString })
        UserDefaults.standard.set(manualOrder, forKey: UserDefaultsKey.manualSortOrder)
    }

    var body: some View {
        NavigationStack {
            AccountList(accounts: $accounts)
                .environmentObject(keychain)
        }
        .onChange(of: accounts) { newValue in
            // This fires when the array changes (i.e., is reordered), but not individual account objects
            // (i.e., it's not a nested observation).
            persistManualSortOrder(of: newValue)
        }
    }
}

#Preview {
    MainScene()
}

extension Account: Identifiable {
    var id: UUID { return uniqueId }
}

struct AccountList: View {

    @Binding var accounts: [Account]
    @EnvironmentObject private var keychain: Keychain

    @State private var isSearching: Bool = false
    @State private var searchText: String = ""
    @State private var filteredAccounts: [Account]

    init(accounts: Binding<[Account]>) {
        _accounts = accounts
        _filteredAccounts = .init(initialValue: accounts.wrappedValue)
    }

    private func handleAccountChanged(_ account: Account) {
        if !keychain.updateAccount(account) {
            // TODO: Display error.
            print("Failed!")
        }
    }

    private func updateFilteredResults(searching accounts: [Account], for searchTerm: String) {
        if searchTerm.isEmpty {
            filteredAccounts = accounts
        } else {
            filteredAccounts = accounts.filter({
                return $0.description.range(of: searchTerm, options: .caseInsensitive, range: nil,
                                            locale: nil) != nil
            })
        }
    }

    var body: some View {
        List {
            if !isSearching {
                ForEach(accounts, content: { account in
                    SUIAccountCell(account: account, commitAccountChange: handleAccountChanged)
                        .id(account.uniqueId)
                })
                .onMove { sourceIndexes, destinationIndex in
                    accounts.move(fromOffsets: sourceIndexes, toOffset: destinationIndex)
                }
            } else {
                ForEach(filteredAccounts, content: { account in
                    SUIAccountCell(account: account, commitAccountChange: handleAccountChanged)
                        .id(account.uniqueId)
                })
            }
        }
        .inClosure { view in
            if #available(iOS 17.0, *) {
                view.searchable(text: $searchText, isPresented: $isSearching, placement: .toolbar,
                                prompt: Text(.searchFieldPlaceholder))
            } else {
                view
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(.accountsViewTitle)
        .onChange(of: searchText) { newValue in
            updateFilteredResults(searching: accounts, for: newValue)
        }
        .onChange(of: accounts) { newAccounts in
            updateFilteredResults(searching: newAccounts, for: searchText)
        }
        .toolbar {
            EditButton()
        }
    }
}
