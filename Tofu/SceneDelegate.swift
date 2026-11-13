//
//  SceneDelegate.swift
//  Tofu
//
//  Created by Daniel Kennett on 2026-11-09.
//  Copyright © 2026 Daniel Kennett. All rights reserved.
//

import Foundation
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    // Asks the delegate to open one or more URLs.
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {

        guard let window, let rootViewController = window.rootViewController else { return }
        guard let accountsViewController = rootViewController.children.first as? AccountsViewController else { return }

        for context in URLContexts {
            let url = context.url

            if url.isFileURL, url.pathExtension == "tofumigration" {
                handleOpeningOfMigrationArchive(at: url, accountDestination: accountsViewController,
                                                presentingIn: rootViewController)
                continue
            }

            guard let account = Account(url: url) else {
                let alert = UIAlertController(
                    title: "Could Not Import Account",
                    message: "The account information was not of the expected format.",
                    preferredStyle: .alert)

                alert.addAction(UIAlertAction(title: "Close", style: .default))
                rootViewController.present(alert, animated: true)
                return
            }

            accountsViewController.createAccount(account)

            let alert = UIAlertController(
                title: "Account Imported",
                message: "Successfully imported \(account.description)",
                preferredStyle: .alert)

            alert.addAction(UIAlertAction(title: "OK", style: .default))
            rootViewController.present(alert, animated: true)
        }
    }

    func handleOpeningOfMigrationArchive(at archiveUrl: URL, accountDestination: AccountCreationDelegate,
                                         presentingIn viewController: UIViewController) {
        guard ExternalDataInterop.appearsToBeValidMigrationDocument(at: archiveUrl),
              let data = try? Data(contentsOf: archiveUrl) else {
            let alert = UIAlertController(
                title: Localizable.migrationDocumentReadingFailedTitle,
                message: Localizable.migrationDocumentReadingFailedMessage,
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Localizable.oKButtonTitle, style: .default))
            viewController.present(alert, animated: true)
            return
        }

        MigrationImportController.presentImport(from: data, at: archiveUrl, into: Keychain().accounts,
                                                importedAccountDestination: accountDestination,
                                                presentingIn: viewController, animated: true)
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}
