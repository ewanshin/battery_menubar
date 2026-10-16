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

    // MARK: Icon for the current charge level

    func testSymbolNameSteps() {
        XCTAssertEqual(BatteryPolicy.symbolName(percent: 0), "battery.0percent")
        XCTAssertEqual(BatteryPolicy.symbolName(percent: 12), "battery.0percent")
        XCTAssertEqual(BatteryPolicy.symbolName(percent: 13), "battery.25percent")
        XCTAssertEqual(BatteryPolicy.symbolName(percent: 37), "battery.25percent")
        XCTAssertEqual(BatteryPolicy.symbolName(percent: 38), "battery.50percent")
        XCTAssertEqual(BatteryPolicy.symbolName(percent: 62), "battery.50percent")
        XCTAssertEqual(BatteryPolicy.symbolName(percent: 63), "battery.75percent")
        XCTAssertEqual(BatteryPolicy.symbolName(percent: 87), "battery.75percent")
        XCTAssertEqual(BatteryPolicy.symbolName(percent: 88), "battery.100percent")
        XCTAssertEqual(BatteryPolicy.symbolName(percent: 100), "battery.100percent")
    }

    func testSymbolNameClampsOutOfRange() {
        XCTAssertEqual(BatteryPolicy.symbolName(percent: -5), "battery.0percent")
        XCTAssertEqual(BatteryPolicy.symbolName(percent: 140), "battery.100percent")
    }

    // MARK: Restoring on quit

    func testRestoreValueIsOriginal() {
        XCTAssertEqual(BatteryPolicy(original: .value(25), hideOverride: nil).restoreValue, .value(25))
        XCTAssertEqual(BatteryPolicy(original: .value(18), hideOverride: 24).restoreValue, .value(18))
        XCTAssertEqual(BatteryPolicy(original: .unset, hideOverride: nil).restoreValue, .unset)
    }
}
