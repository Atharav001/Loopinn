import Foundation
import XCTest
@testable import LoopinnCore

final class SettingsStoreTests: XCTestCase {
    func testAppearancePersistsAcrossStoreInstancesAndResets() throws {
        let suite = "loopinn-settings-test-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = SettingsStore(defaults: defaults)
        XCTAssertEqual(try store.load(), AppSettings())
        try store.save(AppSettings(theme: .dark, accent: .teal))
        XCTAssertEqual(try SettingsStore(defaults: defaults).load().theme, .dark)
        XCTAssertEqual(try SettingsStore(defaults: defaults).load().accent, .teal)
        try store.save(AppSettings())
        XCTAssertEqual(try store.load(), AppSettings())
    }

    func testCorruptSettingsDoNotSilentlyReset() throws {
        let suite = "loopinn-settings-test-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data("bad settings".utf8), forKey: "loopinn.settings.v1")
        XCTAssertThrowsError(try SettingsStore(defaults: defaults).load())
    }
}
