import Foundation

/// The value of the Control Center `Battery` preference as found on disk.
public enum PrefValue: Equatable {
    /// The key is not present in the per-host domain (macOS default applies).
    case unset
    case value(Int)
}

/// What to write to Control Center's per-host preferences on a power change.
public struct PrefChange: Equatable {
    public let battery: Int
    /// `true` to force "show percentage" on; `nil` to leave the key untouched.
    public let showPercentage: Bool?
}

/// Pure decision logic for the menu bar battery item. No I/O.
public struct BatteryPolicy: Equatable {
    /// Value Control Center uses for "Show in Menu Bar".
    public static let showValue = 18
    /// Value used for "Don't Show in Menu Bar" when nothing better is known.
    public static let defaultHideValue = 25

    /// The user's own `Battery` value, captured before the app ever touched it.
    public let original: PrefValue
    /// Optional override for the hide value (`BATTERY_MENUBAR_HIDE_VALUE`).
    public let hideOverride: Int?

    public init(original: PrefValue, hideOverride: Int?) {
        self.original = original
        self.hideOverride = hideOverride
    }

    /// Decide which value counts as the user's original.
    ///
    /// A previously stored original always wins: if the app exited without
    /// restoring (crash, forced quit, shutdown), the current on-disk value was
    /// written by us and is not the user's.
    public static func resolveOriginal(stored: PrefValue?, current: PrefValue) -> PrefValue {
        stored ?? current
    }

    public var hideValue: Int {
        if let hideOverride { return hideOverride }
        if case .value(let v) = original, v != Self.showValue { return v }
        return Self.defaultHideValue
    }

    public func change(onBattery: Bool) -> PrefChange {
        onBattery
            ? PrefChange(battery: Self.showValue, showPercentage: true)
            : PrefChange(battery: hideValue, showPercentage: nil)
    }

    /// What to put back when the app quits normally.
    public var restoreValue: PrefValue { original }
}
