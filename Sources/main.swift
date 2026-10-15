// battery-menubar
// Show the macOS menu bar battery indicator (with percentage) only while
// running on battery power, and hide it while on AC power.
//
// It listens for IOKit power-source change notifications (no polling) and
// flips the Control Center per-host preference that controls the battery
// menu bar item. The change is applied live by Control Center; no restart
// of ControlCenter is required (verified on macOS 27).

import Foundation
import IOKit.ps

let domain = "com.apple.controlcenter" as CFString
let keyBattery = "Battery" as CFString
let keyShowPercentage = "BatteryShowPercentage" as CFString

/// Value Control Center uses for "Show in Menu Bar".
let showValue = 18
/// Value used for "Don't Show in Menu Bar". Defaults to whatever the user
/// already had configured (if it is not the "show" value), otherwise 25.
let hideValue: Int = {
    if let env = ProcessInfo.processInfo.environment["BATTERY_MENUBAR_HIDE_VALUE"],
       let v = Int(env) { return v }
    if let current = CFPreferencesCopyValue(keyBattery, domain,
                                            kCFPreferencesCurrentUser,
                                            kCFPreferencesCurrentHost) as? Int,
       current != showValue { return current }
    return 25
}()

func log(_ message: String) {
    FileHandle.standardError.write("[battery-menubar] \(message)\n".data(using: .utf8)!)
}

func onBattery() -> Bool {
    guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
          let type = IOPSGetProvidingPowerSourceType(info)?.takeUnretainedValue() as String?
    else { return false }
    return type == kIOPSBatteryPowerValue
}

func setPref(_ key: CFString, _ value: CFPropertyList) {
    CFPreferencesSetValue(key, value, domain, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
    CFPreferencesSynchronize(domain, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
}

var lastState: Bool? = nil

func apply() {
    let battery = onBattery()
    if battery == lastState { return }
    lastState = battery
    setPref(keyBattery, (battery ? showValue : hideValue) as CFNumber)
    if battery { setPref(keyShowPercentage, kCFBooleanTrue) }
    log(battery ? "on battery -> show" : "on AC -> hide")
}

log("started (hide value = \(hideValue))")
apply()

let source = IOPSNotificationCreateRunLoopSource({ _ in apply() }, nil).takeRetainedValue()
CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
CFRunLoopRun()
