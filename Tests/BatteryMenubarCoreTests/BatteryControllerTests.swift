import XCTest
@testable import BatteryMenubarCore

/// In-memory stand-in for Control Center's per-host preferences.
final class FakePrefs: ControlCenterPrefs {
    var battery: PrefValue
    var showPercentage: Bool?
    var writes: [PrefValue] = []

    init(battery: PrefValue) { self.battery = battery }

    func readBattery() -> PrefValue { battery }
    func writeBattery(_ value: PrefValue) { battery = value; writes.append(value) }
    func writeShowPercentage(_ on: Bool) { showPercentage = on }
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

    func testCapturesOriginalFromPrefsOnFirstLaunch() {
        let prefs = FakePrefs(battery: .value(25))
        _ = makeController(prefs: prefs)
        XCTAssertEqual(store.load(), .value(25))
    }

    func testKeepsStoredOriginalOverCurrentPrefs() {
        store.save(.value(25))
        let prefs = FakePrefs(battery: .value(18))  // left behind by an unclean exit
        let controller = makeController(prefs: prefs)
        XCTAssertEqual(store.load(), .value(25))
        XCTAssertEqual(controller.policy.original, .value(25))
    }

    func testOnBatteryShowsAndForcesPercentage() {
        let prefs = FakePrefs(battery: .value(25))
        let controller = makeController(prefs: prefs)
        controller.update(onBattery: true)
        XCTAssertEqual(prefs.battery, .value(18))
        XCTAssertEqual(prefs.showPercentage, true)
    }

    func testOnACHidesWithoutTouchingPercentage() {
        let prefs = FakePrefs(battery: .value(25))
        let controller = makeController(prefs: prefs)
        controller.update(onBattery: false)
        XCTAssertEqual(prefs.battery, .value(25))
        XCTAssertNil(prefs.showPercentage)
    }

    func testUnchangedStateWritesOnlyOnce() {
        let prefs = FakePrefs(battery: .value(25))
        let controller = makeController(prefs: prefs)
        controller.update(onBattery: true)
        controller.update(onBattery: true)
        XCTAssertEqual(prefs.writes.count, 1)
    }

    func testStateChangeNotifiesObserver() {
        let prefs = FakePrefs(battery: .value(25))
        let controller = makeController(prefs: prefs)
        var seen: [Bool] = []
        controller.onChange = { seen.append($0) }
        controller.update(onBattery: true)
        controller.update(onBattery: true)
        controller.update(onBattery: false)
        XCTAssertEqual(seen, [true, false])
    }

    func testRestoreWritesOriginalAndForgetsIt() {
        let prefs = FakePrefs(battery: .value(25))
        let controller = makeController(prefs: prefs)
        controller.update(onBattery: true)
        controller.restoreAndForget()
        XCTAssertEqual(prefs.battery, .value(25))
        XCTAssertNil(store.load())
    }

    func testRestoreRemovesKeyWhenOriginalWasUnset() {
        let prefs = FakePrefs(battery: .unset)
        let controller = makeController(prefs: prefs)
        controller.update(onBattery: false)
        controller.restoreAndForget()
        XCTAssertEqual(prefs.battery, .unset)
    }
}
