import Foundation

/// Access to Control Center's per-host `Battery` preferences.
public protocol ControlCenterPrefs {
    func readBattery() -> PrefValue
    func writeBattery(_ value: PrefValue)
    func writeShowPercentage(_ on: Bool)
}

/// The real thing: `com.apple.controlcenter` in the current user's per-host domain.
/// Control Center observes this domain and applies changes live.
public struct LiveControlCenterPrefs: ControlCenterPrefs {
    private let domain = "com.apple.controlcenter" as CFString
    private let keyBattery = "Battery" as CFString
    private let keyShowPercentage = "BatteryShowPercentage" as CFString

    public init() {}

    public func readBattery() -> PrefValue {
        guard let v = CFPreferencesCopyValue(keyBattery, domain,
                                             kCFPreferencesCurrentUser,
                                             kCFPreferencesCurrentHost) as? Int
        else { return .unset }
        return .value(v)
    }

    public func writeBattery(_ value: PrefValue) {
        switch value {
        case .unset: set(keyBattery, nil)
        case .value(let v): set(keyBattery, v as CFNumber)
        }
    }

    public func writeShowPercentage(_ on: Bool) {
        set(keyShowPercentage, on ? kCFBooleanTrue : kCFBooleanFalse)
    }

    private func set(_ key: CFString, _ value: CFPropertyList?) {
        CFPreferencesSetValue(key, value, domain, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
        CFPreferencesSynchronize(domain, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
    }
}
