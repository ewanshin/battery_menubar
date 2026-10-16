import XCTest
@testable import BatteryMenubarCore

final class BatteryPolicyTests: XCTestCase {

    // MARK: Resolving the original value at startup

    func testOriginalIsTakenFromCurrentWhenNothingStored() {
        XCTAssertEqual(BatteryPolicy.resolveOriginal(stored: nil, current: .value(25)), .value(25))
    }

    func testOriginalIsUnsetWhenNothingStoredAndKeyMissing() {
        XCTAssertEqual(BatteryPolicy.resolveOriginal(stored: nil, current: .unset), .unset)
    }

    func testStoredOriginalWinsOverCurrentAfterUncleanExit() {
        // The app may have exited without restoring; the current value is ours, not the user's.
        XCTAssertEqual(BatteryPolicy.resolveOriginal(stored: .value(25), current: .value(18)), .value(25))
    }

    func testStoredUnsetOriginalWinsOverCurrent() {
        XCTAssertEqual(BatteryPolicy.resolveOriginal(stored: .unset, current: .value(18)), .unset)
    }

    // MARK: Hide value

    func testHideValueIsOriginalWhenOriginalIsNotShow() {
        let policy = BatteryPolicy(original: .value(25), hideOverride: nil)
        XCTAssertEqual(policy.hideValue, 25)
    }

    func testHideValueFallsBackTo25WhenOriginalIsShow() {
        let policy = BatteryPolicy(original: .value(18), hideOverride: nil)
        XCTAssertEqual(policy.hideValue, 25)
    }

    func testHideValueFallsBackTo25WhenOriginalIsUnset() {
        let policy = BatteryPolicy(original: .unset, hideOverride: nil)
        XCTAssertEqual(policy.hideValue, 25)
    }

    func testHideValueOverrideWins() {
        let policy = BatteryPolicy(original: .value(25), hideOverride: 24)
        XCTAssertEqual(policy.hideValue, 24)
    }

    // MARK: Values written on power change

    func testOnBatteryShowsWithPercentage() {
        let policy = BatteryPolicy(original: .value(25), hideOverride: nil)
        let change = policy.change(onBattery: true)
        XCTAssertEqual(change.battery, 18)
        XCTAssertEqual(change.showPercentage, true)
    }

    func testOnACHidesAndLeavesPercentageAlone() {
        let policy = BatteryPolicy(original: .value(25), hideOverride: nil)
        let change = policy.change(onBattery: false)
        XCTAssertEqual(change.battery, 25)
        XCTAssertNil(change.showPercentage)
    }

    // MARK: Restoring on quit

    func testRestoreValueIsOriginal() {
        XCTAssertEqual(BatteryPolicy(original: .value(25), hideOverride: nil).restoreValue, .value(25))
        XCTAssertEqual(BatteryPolicy(original: .value(18), hideOverride: 24).restoreValue, .value(18))
        XCTAssertEqual(BatteryPolicy(original: .unset, hideOverride: nil).restoreValue, .unset)
    }
}
