protocol AccountCreationDelegate: class {
    func createAccount(_ account: Account)
    func rejectAccount()
}
