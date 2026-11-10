protocol AccountCreationDelegate: AnyObject {
    func createAccount(_ account: Account)
    func createAccounts(_ accounts: [Account])
}
