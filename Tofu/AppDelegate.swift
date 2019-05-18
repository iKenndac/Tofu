import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        return true
    }

    func application(_ application: UIApplication,
                     open url: URL,
                     options: [UIApplicationOpenURLOptionsKey : Any] = [:] ) -> Bool {

        let rootViewController = window!.rootViewController!

        guard let account = Account(url: url) else {
            let alert = UIAlertController(
                title: "Could not import account",
                message: "The account information was not of the expected format.",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))

            rootViewController.present(alert, animated: true, completion: nil)
            return false
        }

        let accountsViewController = rootViewController.childViewControllers.first as! AccountsViewController
        
        accountsViewController.createAccount(account)

        let alert = UIAlertController(
            title: "Account Imported",
            message: "Successfully imported \(account.description)",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        rootViewController.present(alert, animated: true, completion: nil)
        
        return true
    }
}
