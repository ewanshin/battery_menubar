import Foundation

/// The value of the Control Center `Battery` preference as found on disk.
public enum PrefValue: Equatable {
    /// The key is not present in the per-host domain (macOS default applies).
    case unset
    case value(Int)
}

/// A snapshot of the Mac's power source.
public struct PowerStatus: Equatable {
    public let onBattery: Bool
    /// Charge level, 0...100.
    public let percent: Int

    public init(onBattery: Bool, percent: Int) {
        self.onBattery = onBattery
        self.percent = percent
    }
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

    /// Value that hides the system battery item while the app runs.
    public var hideValue: Int {
        if let hideOverride { return hideOverride }
        if case .value(let v) = original, v != Self.showValue { return v }
        return Self.defaultHideValue
    }

    /// What to put back when the app quits normally.
    public var restoreValue: PrefValue { original }

    /// SF Symbol for a charge level, in the five steps the system glyphs come in.
    public static func symbolName(percent: Int) -> String {
        let step: Int
        switch max(0, min(100, percent)) {
        case 0...12: step = 0
        case 13...37: step = 25
        case 38...62: step = 50
        case 63...87: step = 75
        default: step = 100
        }
        return "battery.\(step)percent"
    }
}
