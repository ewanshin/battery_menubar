import Foundation

/// Applies `BatteryPolicy` to Control Center preferences, writing only when
/// the power state actually changes, and restores the user's original
/// setting on a normal quit.
public final class BatteryController {
    public let policy: BatteryPolicy
    /// Current state, `nil` until the first `update`.
    public private(set) var onBattery: Bool?
    /// Called whenever the state flips (not on repeated identical updates).
    public var onChange: ((Bool) -> Void)?

    private let prefs: ControlCenterPrefs
    private let store: OriginalValueStore

    public init(prefs: ControlCenterPrefs, store: OriginalValueStore, hideOverride: Int?) {
        self.prefs = prefs
        self.store = store
        let original = BatteryPolicy.resolveOriginal(stored: store.load(), current: prefs.readBattery())
        store.save(original)
        self.policy = BatteryPolicy(original: original, hideOverride: hideOverride)
    }

    public func update(onBattery battery: Bool) {
        if battery == onBattery { return }
        onBattery = battery
        let change = policy.change(onBattery: battery)
        prefs.writeBattery(.value(change.battery))
        if let show = change.showPercentage { prefs.writeShowPercentage(show) }
        onChange?(battery)
    }

    public func restoreAndForget() {
        prefs.writeBattery(policy.restoreValue)
        store.clear()
    }
}
