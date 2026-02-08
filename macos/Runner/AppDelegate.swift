import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    var statusBarController: StatusBarController?
    var trayChannel: FlutterMethodChannel?

    override func applicationDidFinishLaunching(_ notification: Notification) {
        // Get the FlutterViewController from the main window
        guard let window = mainFlutterWindow,
              let controller = window.contentViewController as? FlutterViewController else {
            return
        }

        // Create MethodChannel
        trayChannel = FlutterMethodChannel(
            name: "com.focusflow/tray",
            binaryMessenger: controller.engine.binaryMessenger
        )

        // Create StatusBarController
        statusBarController = StatusBarController(channel: trayChannel!)

        // Set MethodChannel handler
        trayChannel!.setMethodCallHandler { [weak self] (call, result) in
            self?.statusBarController?.handle(call, result: result)
        }
    }

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
