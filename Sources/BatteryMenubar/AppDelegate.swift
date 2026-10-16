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
        controller.onChange = { [weak self] battery in
            self?.log.info("\(battery ? "on battery -> show" : "on AC -> hide", privacy: .public)")
            self?.refresh(onBattery: battery)
        }
        controller.update(onBattery: PowerWatcher.isOnBattery())
        watcher = PowerWatcher { [weak self] in
            self?.controller.update(onBattery: PowerWatcher.isOnBattery())
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller.restoreAndForget()
        log.info("quit -> restored original battery setting")
    }

    // MARK: Menu

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
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

    /// Our own icon appears only while on battery, next to the system battery
    /// item; on AC the menu bar shows nothing from us.
    private func refresh(onBattery battery: Bool) {
        statusItem.isVisible = battery
        guard battery else { return }
        let image = NSImage(systemSymbolName: "bolt.slash", accessibilityDescription: "On battery")
        image?.isTemplate = true
        statusItem.button?.image = image
        stateItem.title = "On battery: battery icon shown"
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
            let alert = NSAlert(error: error)
            alert.runModal()
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
