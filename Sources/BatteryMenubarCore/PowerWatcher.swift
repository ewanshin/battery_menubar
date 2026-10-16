import Foundation
import IOKit.ps

/// Fires a handler on the main run loop whenever IOKit reports a power-source
/// change (source switch or charge level). No polling.
public final class PowerWatcher {
    private let handler: () -> Void
    private var source: CFRunLoopSource?

    public init(handler: @escaping () -> Void) {
        self.handler = handler
        let context = Unmanaged.passUnretained(self).toOpaque()
        source = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else { return }
            Unmanaged<PowerWatcher>.fromOpaque(context).takeUnretainedValue().handler()
        }, context).takeRetainedValue()
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
    }

    deinit {
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode) }
    }

    /// Current power source and charge level of the internal battery.
    public static func current() -> PowerStatus {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
            return PowerStatus(onBattery: false, percent: 0)
        }
        let type = IOPSGetProvidingPowerSourceType(info)?.takeUnretainedValue() as String?
        let onBattery = type == kIOPSBatteryPowerValue

        var percent = 0
        if let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] {
            for source in list {
                guard let desc = IOPSGetPowerSourceDescription(info, source)?
                        .takeUnretainedValue() as? [String: Any],
                      desc[kIOPSTypeKey] as? String == kIOPSInternalBatteryType,
                      let current = desc[kIOPSCurrentCapacityKey] as? Int,
                      let max = desc[kIOPSMaxCapacityKey] as? Int, max > 0
                else { continue }
                percent = current * 100 / max
                break
            }
        }
        return PowerStatus(onBattery: onBattery, percent: percent)
    }
}
