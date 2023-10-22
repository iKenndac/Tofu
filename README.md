# Tofu

An easy-to-use, open-source two-factor authentication app designed specifically
for iOS.

Tofu generates one-time passwords to help you protect your online accounts.
These passwords are used together with your normal password when you sign into
services like Google, Facebook, Dropbox, Amazon, and GitHub.

Tofu works with all services that provide two-factor authentication using the
HOTP and TOTP algorithms. It does not require a network or cellular connection
and can be used in airplane mode.

## New maintainer

Hey there, [Calle](https://github.com/calleluks) here, the original author of Tofu Authenticator. Over the last few years I haven’t had as much time to work on the app as I had hoped for. While Tofu has been working fine (I still use the app every day), few improvements have been made and no new platform features have been integrated. Luckily, my friend [Daniel Kennett](https://github.com/ikenndac) who is both a long-time user of Tofu and a way more experienced iOS developer than I am, has offered to take over maintenance and ownership of the app going forward. I’m really thankful for being able to place the app in Daniel’s safe hands and look forward to following the future development of it!

## Installation

Tofu is available for free on the App Store.

[![Download on the App Store](https://tofuauth.com/images/app-store.svg)](https://itunes.apple.com/app/tofu-authenticator/id1082229305)

## Issuer icons

Here's how you can help add new icons to the app:

1. Fork and clone this repo.

2. Add your icon to the `IssuerIcons/` directory.

   The icon should be a square PNG without rounded corners and without borders.
   It must be at least 196x196 pixels but we prefer larger sizes such as
   1024x1024.

3. Run `./GenerateIssuerIconAssets.sh` from the root of the repo.

4. Add an entry for the icon to [the `imageNames` dictionary](https://github.com/calleerlandsson/Tofu/blob/master/Tofu/AccountCell.swift#L15).

   The key should be the string that shows up in the account's Issuer field
   when scanning a QR code for the service. The value should be the name of the
   icon file.

5. Commit your changes and open a PR.

Here's an example commit for adding a new icon: [692e32a](https://github.com/calleerlandsson/Tofu/commit/692e32a9744bcaa360e4d7db9f00c4e90f6f66ac)

If you don't feel comfortable adding icons yourself, you can ask others to do
so by [opening issues using the Issuer Icon Request template](https://github.com/calleerlandsson/Tofu/issues/new?labels=icon+request&template=issuer-icon-request.md&title=Add+an+icon+for+Example).

## Beta testing

To avoid releasing broken versions of Tofu on the App Store, we rely on beta
testers to discover and report bugs and other issues.

If you'd like to help us test new versions of the app, use this link to join
the TestFlight beta: https://testflight.apple.com/join/LLe6CFdo

To leave the beta, open the TestFlight app, tap on Tofu Authenticator, scroll
to the bottom and tap on "Stop Testing". Then re-install the release version of
Tofu from the App Store.
