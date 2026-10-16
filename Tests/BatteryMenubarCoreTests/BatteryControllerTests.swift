import XCTest
@testable import BatteryMenubarCore

/// In-memory stand-in for Control Center's per-host preferences.
final class FakePrefs: ControlCenterPrefs {
    var battery: PrefValue
    var writes: [PrefValue] = []

    init(battery: PrefValue) { self.battery = battery }

    func readBattery() -> PrefValue { battery }
    func writeBattery(_ value: PrefValue) { battery = value; writes.append(value) }
}

final class BatteryControllerTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "local.battery-menubar.controller-tests"
    private var store: OriginalValueStore!

    override func setUp() {
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
        store = OriginalValueStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
    }

    private func makeController(prefs: FakePrefs, hideOverride: Int? = nil) -> BatteryController {
        BatteryController(prefs: prefs, store: store, hideOverride: hideOverride)
    }

    // MARK: Start

    func testCapturesOriginalFromPrefsOnFirstLaunch() {
        let prefs = FakePrefs(battery: .value(18))
        _ = makeController(prefs: prefs)
        XCTAssertEqual(store.load(), .value(18))
    }

    func testKeepsStoredOriginalOverCurrentPrefs() {
        store.save(.value(18))
        let prefs = FakePrefs(battery: .value(25))  // left behind by an unclean exit
        let controller = makeController(prefs: prefs)
        XCTAssertEqual(store.load(), .value(18))
        XCTAssertEqual(controller.policy.original, .value(18))
    }

    func testHidesSystemBatteryItemOnStart() {
        let prefs = FakePrefs(battery: .value(18))
        _ = makeController(prefs: prefs)
        XCTAssertEqual(prefs.battery, .value(25))
    }

    func testHidesWithOverrideValue() {
        let prefs = FakePrefs(battery: .value(18))
        _ = makeController(prefs: prefs, hideOverride: 24)
        XCTAssertEqual(prefs.battery, .value(24))
    }

    // MARK: Power updates

    func testUpdateDoesNotTouchSystemPrefs() {
        let prefs = FakePrefs(battery: .value(18))
        let controller = makeController(prefs: prefs)
        controller.update(PowerStatus(onBattery: true, percent: 80))
        controller.update(PowerStatus(onBattery: false, percent: 80))
        XCTAssertEqual(prefs.writes.count, 1)  // only the initial hide
    }

    func testObserverSeesEachChangeOnce() {
        let prefs = FakePrefs(battery: .value(18))
        let controller = makeController(prefs: prefs)
        var seen: [PowerStatus] = []
        controller.onChange = { seen.append($0) }
        controller.update(PowerStatus(onBattery: true, percent: 80))
        controller.update(PowerStatus(onBattery: true, percent: 80))
        controller.update(PowerStatus(onBattery: true, percent: 79))
        controller.update(PowerStatus(onBattery: false, percent: 79))
        XCTAssertEqual(seen, [
            PowerStatus(onBattery: true, percent: 80),
            PowerStatus(onBattery: true, percent: 79),
            PowerStatus(onBattery: false, percent: 79),
        ])
    }

    func testStatusIsExposed() {
        let prefs = FakePrefs(battery: .value(18))
        let controller = makeController(prefs: prefs)
        XCTAssertNil(controller.status)
        controller.update(PowerStatus(onBattery: true, percent: 50))
        XCTAssertEqual(controller.status, PowerStatus(onBattery: true, percent: 50))
    }

    // MARK: Quit

    func testRestoreWritesOriginalAndForgetsIt() {
        let prefs = FakePrefs(battery: .value(18))
        let controller = makeController(prefs: prefs)
        controller.restoreAndForget()
        XCTAssertEqual(prefs.battery, .value(18))
        XCTAssertNil(store.load())
    }

    func testRestoreRemovesKeyWhenOriginalWasUnset() {
        let prefs = FakePrefs(battery: .unset)
        let controller = makeController(prefs: prefs)
        controller.restoreAndForget()
        XCTAssertEqual(prefs.battery, .unset)
    }
}
