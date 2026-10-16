import Foundation

/// Hides the system battery item for as long as the app runs, tracks the
/// power status for the app's own menu bar item, and restores the user's
/// original setting on a normal quit.
public final class BatteryController {
    public let policy: BatteryPolicy
    /// Latest power status, `nil` until the first `update`.
    public private(set) var status: PowerStatus?
    /// Called whenever the status changes (not on repeated identical updates).
    public var onChange: ((PowerStatus) -> Void)?

    private let prefs: ControlCenterPrefs
    private let store: OriginalValueStore

    public init(prefs: ControlCenterPrefs, store: OriginalValueStore, hideOverride: Int?) {
        self.prefs = prefs
        self.store = store
        let original = BatteryPolicy.resolveOriginal(stored: store.load(), current: prefs.readBattery())
        store.save(original)
        self.policy = BatteryPolicy(original: original, hideOverride: hideOverride)
        prefs.writeBattery(.value(policy.hideValue))
    }

    public func update(_ newStatus: PowerStatus) {
        if newStatus == status { return }
        status = newStatus
        onChange?(newStatus)
    }

    public func restoreAndForget() {
        prefs.writeBattery(policy.restoreValue)
        store.clear()
    }
}
