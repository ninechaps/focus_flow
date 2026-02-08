import Cocoa
import FlutterMacOS
import SwiftUI

/// Manages the macOS status bar item (tray icon), NSPopover for focus preview,
/// and right-click context menu. Communicates with Dart via MethodChannel.
class StatusBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover
    private var contextMenu: NSMenu
    private let channel: FlutterMethodChannel
    private let popoverState = PopoverState()
    private var eventMonitor: Any?

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        self.popover = NSPopover()
        self.contextMenu = NSMenu()
        super.init()

        setupStatusItem()
        setupPopover()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }
        button.target = self
        button.action = #selector(statusBarButtonClicked(_:))
        button.sendAction(on: [.leftMouseDown, .rightMouseDown])
    }

    private func setupPopover() {
        let popoverView = FocusPopoverView(
            state: popoverState,
            onAction: { [weak self] action in
                self?.handlePopoverAction(action)
            }
        )
        popover.contentViewController = NSHostingController(rootView: popoverView)
        popover.contentSize = NSSize(width: 300, height: 360)
        popover.behavior = .transient
        popover.animates = true
    }

    // MARK: - Mouse Events

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseDown {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem?.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

        // Monitor clicks outside the popover to close it
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func showContextMenu() {
        guard let button = statusItem?.button else { return }
        // Close popover if open before showing menu
        if popover.isShown {
            closePopover()
        }
        statusItem?.menu = contextMenu
        button.performClick(nil)
        statusItem?.menu = nil // Reset so left-click works again
    }

    // MARK: - Popover Actions

    private func handlePopoverAction(_ action: String) {
        closePopover()
        channel.invokeMethod("onPopoverAction", arguments: ["action": action])
    }

    // MARK: - MethodChannel Handler

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setIcon":
            handleSetIcon(call.arguments as? [String: Any], result: result)
        case "setTitle":
            handleSetTitle(call.arguments as? [String: Any], result: result)
        case "setToolTip":
            handleSetToolTip(call.arguments as? [String: Any], result: result)
        case "setContextMenu":
            handleSetContextMenu(call.arguments as? [String: Any], result: result)
        case "popUpContextMenu":
            showContextMenu()
            result(nil)
        case "updatePopoverState":
            handleUpdatePopoverState(call.arguments as? [String: Any], result: result)
        case "destroy":
            destroy()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Icon

    private func handleSetIcon(_ args: [String: Any]?, result: FlutterResult) {
        guard let args = args,
              let base64String = args["base64Icon"] as? String,
              let imageData = Data(base64Encoded: base64String) else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing base64Icon", details: nil))
            return
        }

        guard let image = NSImage(data: imageData) else {
            result(FlutterError(code: "INVALID_IMAGE", message: "Failed to decode image", details: nil))
            return
        }

        let isTemplate = args["isTemplate"] as? Bool ?? true
        let iconSize = args["iconSize"] as? Double ?? 18.0

        image.isTemplate = isTemplate
        image.size = NSSize(width: iconSize, height: iconSize)
        statusItem?.button?.image = image

        result(nil)
    }

    // MARK: - Title

    private func handleSetTitle(_ args: [String: Any]?, result: FlutterResult) {
        let title = args?["title"] as? String ?? ""
        statusItem?.button?.title = title
        result(nil)
    }

    // MARK: - ToolTip

    private func handleSetToolTip(_ args: [String: Any]?, result: FlutterResult) {
        let toolTip = args?["toolTip"] as? String ?? ""
        statusItem?.button?.toolTip = toolTip
        result(nil)
    }

    // MARK: - Context Menu

    private func handleSetContextMenu(_ args: [String: Any]?, result: FlutterResult) {
        guard let args = args,
              let items = args["items"] as? [[String: Any]] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing items", details: nil))
            return
        }

        contextMenu.removeAllItems()

        for item in items {
            let type = item["type"] as? String ?? "normal"

            if type == "separator" {
                contextMenu.addItem(NSMenuItem.separator())
                continue
            }

            let label = item["label"] as? String ?? ""
            let key = item["key"] as? String ?? ""
            let disabled = item["disabled"] as? Bool ?? false

            let menuItem = NSMenuItem(
                title: label,
                action: disabled ? nil : #selector(contextMenuItemClicked(_:)),
                keyEquivalent: ""
            )
            menuItem.target = self
            menuItem.representedObject = key
            menuItem.isEnabled = !disabled

            contextMenu.addItem(menuItem)
        }

        result(nil)
    }

    @objc private func contextMenuItemClicked(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String else { return }
        channel.invokeMethod("onMenuItemClick", arguments: ["key": key])
    }

    // MARK: - Popover State

    private func handleUpdatePopoverState(_ args: [String: Any]?, result: FlutterResult) {
        guard let args = args else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let state = self?.popoverState else { return }
            if let focusState = args["focusState"] as? String {
                state.focusState = focusState
            }
            if let taskName = args["taskName"] as? String {
                state.taskName = taskName
            }
            if let formattedTime = args["formattedTime"] as? String {
                state.formattedTime = formattedTime
            }
            if let progress = args["progress"] as? Double {
                state.progress = progress
            }
            if let timerMode = args["timerMode"] as? String {
                state.timerMode = timerMode
            }
            if let sessionTime = args["sessionTime"] as? String {
                state.sessionTime = sessionTime
            }
            if let totalTime = args["totalTime"] as? String {
                state.totalTime = totalTime
            }
            if let sessions = args["sessions"] as? Int {
                state.sessions = sessions
            }
            if let breadcrumb = args["breadcrumb"] as? String {
                state.breadcrumb = breadcrumb
            }
        }

        result(nil)
    }

    // MARK: - Cleanup

    func destroy() {
        closePopover()
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil
    }
}
