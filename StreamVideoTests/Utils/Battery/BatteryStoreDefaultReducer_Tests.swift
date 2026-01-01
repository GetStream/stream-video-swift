//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import UIKit
import XCTest

final class BatteryStoreDefaultReducer_Tests: XCTestCase, @unchecked Sendable {

    private var reducer: BatteryStore.Namespace.DefaultReducer!
    private var state: BatteryStore.Namespace.StoreState!

    override func setUp() {
        super.setUp()
        reducer = .init()
        state = .init(isMonitoringEnabled: false, state: .unknown, level: 0)
    }

    override func tearDown() {
        state = nil
        reducer = nil
        super.tearDown()
    }

    func test_reduce_setLevel_roundsAndClamps() async throws {
        let updated = try await reducer.reduce(
            state: state,
            action: .setLevel(0.736),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(updated.level, 74)
        XCTAssertEqual(state.level, 0)
    }

    func test_reduce_setLevel_handlesNegativeValues() async throws {
        let updated = try await reducer.reduce(
            state: state,
            action: .setLevel(-0.2),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(updated.level, 0)
    }

    func test_reduce_setState_updatesBatteryState() async throws {
        let updated = try await reducer.reduce(
            state: state,
            action: .setState(.full),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertEqual(updated.state, .full)
    }

    #if canImport(UIKit)
    func test_reduce_setMonitoringEnabled_updatesFlagAndDevice() async throws {
        await MainActor.run {
            UIDevice.current.isBatteryMonitoringEnabled = false
        }

        let updated = try await reducer.reduce(
            state: state,
            action: .setMonitoringEnabled(true),
            file: #file,
            function: #function,
            line: #line
        )

        XCTAssertTrue(updated.isMonitoringEnabled)
    }
    #endif
}
