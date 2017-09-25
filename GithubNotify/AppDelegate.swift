
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let STATUS_ITEM = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(AppDelegate.handleGetURL(event:withReplyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))

        if let button = STATUS_ITEM.button {
            button.image = NSImage(named: "MenuIconDefault")
            button.action = #selector(togglePopover(_:))
        }

        InitGithub()
        Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(AppDelegate.refresh), userInfo: nil, repeats: true)

    }

    
    func applicationWillTerminate(_ aNotification: Notification) {
    }

    @objc
    func togglePopover(_ sender: Any?) {
        NSWorkspace.shared().open(URL(string: "https://github.com/notifications")!)
    }

    func refresh() {
        print("refreshing!")
        updateNotifications()
    }

    func handleGetURL(event: NSAppleEventDescriptor!, withReplyEvent: NSAppleEventDescriptor!) {
        if let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
            let url = URL(string: urlString) {

            if url.scheme == "github-notify" {
                HandleGithubOAuthURL(url: url)
            }

        }
    }
}

