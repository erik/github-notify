
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let STATUS_ITEM = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let button = STATUS_ITEM.button {
            button.image = NSImage(named: "MenuIconDefault")
            button.action = #selector(togglePopover(_:))
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }

    @objc
    func togglePopover(_ sender: Any?) {
        print("dongs")
    }
}

