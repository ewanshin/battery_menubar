import XCTest
@testable import BatteryMenubarCore

final class OriginalValueStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "local.battery-menubar.tests"

    override func setUp() {
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
    }

    func testLoadReturnsNilWhenNothingSaved() {
        XCTAssertNil(OriginalValueStore(defaults: defaults).load())
    }

    func testSavedValueRoundTrips() {
        let store = OriginalValueStore(defaults: defaults)
        store.save(.value(25))
        XCTAssertEqual(store.load(), .value(25))
    }

    func testSavedUnsetRoundTrips() {
        let store = OriginalValueStore(defaults: defaults)
        store.save(.unset)
        XCTAssertEqual(store.load(), .unset)
    }

    func testClearForgetsSavedValue() {
        let store = OriginalValueStore(defaults: defaults)
        store.save(.value(25))
        store.clear()
        XCTAssertNil(store.load())
    }
}
