import AppKit
import ServiceManagement
import os
import BatteryMenubarCore

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let log = Logger(subsystem: "io.github.ewanshin.battery-menubar", category: "app")
    private var statusItem: NSStatusItem!
    private let stateItem = NSMenuItem()
    private let loginItem = NSMenuItem(title: "Launch at Login",
                                       action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
    private var controller: BatteryController!
    private var watcher: PowerWatcher!

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller = BatteryController(prefs: LiveControlCenterPrefs(),
                                       store: OriginalValueStore(),
                                       hideOverride: Self.hideOverride())
        log.info("started (original = \(String(describing: self.controller.policy.original), privacy: .public), hide = \(self.controller.policy.hideValue))")

        setUpStatusItem()
        controller.onChange = { [weak self] status in
            self?.log.info("\(status.onBattery ? "on battery" : "on AC", privacy: .public) \(status.percent)%")
            self?.refresh(status)
        }
        controller.update(PowerWatcher.current())
        watcher = PowerWatcher { [weak self] in
            self?.controller.update(PowerWatcher.current())
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller.restoreAndForget()
        log.info("quit -> restored original battery setting")
    }

    // MARK: Menu bar item

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.imagePosition = .imageLeading
        statusItem.button?.font = NSFont.menuBarFont(ofSize: 0)
        let menu = NSMenu()
        menu.delegate = self
        stateItem.isEnabled = false
        menu.addItem(stateItem)
        menu.addItem(.separator())
        loginItem.target = self
        menu.addItem(loginItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit BatteryMenubar",
                                action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    /// A battery glyph plus percentage, shown only while on battery. On AC the
    /// menu bar shows nothing from the app (and the system item stays hidden).
    private func refresh(_ status: PowerStatus) {
        statusItem.isVisible = status.onBattery
        guard status.onBattery, let button = statusItem.button else { return }
        let image = NSImage(systemSymbolName: BatteryPolicy.symbolName(percent: status.percent),
                            accessibilityDescription: "Battery \(status.percent)%")
        image?.isTemplate = true
        button.image = image
        button.title = " \(status.percent)%"
        stateItem.title = "\(status.percent)%, on battery"
    }

    func menuWillOpen(_ menu: NSMenu) {
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            switch service.status {
            case .enabled:
                try service.unregister()
            case .requiresApproval:
                SMAppService.openSystemSettingsLoginItems()
            default:
                try service.register()
            }
        } catch {
            log.error("launch at login failed: \(error.localizedDescription, privacy: .public)")
            NSAlert(error: error).runModal()
        }
    }

    // MARK: Configuration

    /// `BATTERY_MENUBAR_HIDE_VALUE` env var, or `defaults write <bundle id> hideValue -int N`.
    private static func hideOverride() -> Int? {
        if let env = ProcessInfo.processInfo.environment["BATTERY_MENUBAR_HIDE_VALUE"], let v = Int(env) {
            return v
        }
        return UserDefaults.standard.object(forKey: "hideValue") as? Int
    }
}
