import Foundation

extension URL {

    var isInAppInbox: Bool {
        do {
            var inboxUrl = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            inboxUrl.appendPathComponent("Inbox", isDirectory: true)
            let inboxPath = inboxUrl.standardized.resolvingSymlinksInPath().path.appending("/")
            let thisPath = standardized.resolvingSymlinksInPath().path
            return thisPath.hasPrefix(inboxPath)
        } catch _ {
            return false
        }
    }
}
