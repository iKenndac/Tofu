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
                preferredStyle: UIAlertControllerStyle.alert
            )

            alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.default, handler: nil))

            rootViewController.present(alert, animated: true, completion: nil)
            return false
        }

        let accountsViewController = rootViewController.childViewControllers.first as! AccountsViewController
        
        accountsViewController.createAccount(account)
        self.noticeOnlyText("Added account '\(account.description)'")

        return true
    }
}
