import Foundation

/// Persists the user's original `Battery` preference across app launches so a
/// crash or forced quit never loses it.
public struct OriginalValueStore {
    private static let hasKey = "hasOriginalBatteryValue"
    private static let valueKey = "originalBatteryValue"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> PrefValue? {
        guard defaults.bool(forKey: Self.hasKey) else { return nil }
        if let number = defaults.object(forKey: Self.valueKey) as? NSNumber {
            return .value(number.intValue)
        }
        return .unset
    }

    public func save(_ value: PrefValue) {
        defaults.set(true, forKey: Self.hasKey)
        switch value {
        case .unset: defaults.removeObject(forKey: Self.valueKey)
        case .value(let v): defaults.set(v, forKey: Self.valueKey)
        }
    }

    public func clear() {
        defaults.removeObject(forKey: Self.hasKey)
        defaults.removeObject(forKey: Self.valueKey)
    }
}
