//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class BatteryStore_Tests: XCTestCase, @unchecked Sendable {

    private var store: Store<BatteryStore.Namespace>!
    private var subject: BatteryStore!

    override func setUp() async throws {
        try await super.setUp()
        store = BatteryStore.Namespace.store(
            initialState: .init(
                isMonitoringEnabled: true,
                state: .unknown,
                level: 0
            ),
            reducers: BatteryStore.Namespace.reducers(),
            middleware: []
        )
        subject = BatteryStore(store: store)

        await wait(for: 0.5)
    }

    override func tearDown() {
        subject = nil
        store = nil
        super.tearDown()
    }

    // MARK: - Encoding

    func test_encode_capturesCurrentState() async throws {
        let task = subject.dispatch([
            .setState(.charging),
            .setLevel(0.91)
        ])
        try await task.result()

        let currentState = subject.state
        XCTAssertTrue(currentState.isMonitoringEnabled)
        XCTAssertEqual(currentState.level, 91)
        XCTAssertEqual(currentState.state, .charging)
    }

    // MARK: - Level Handling

    func test_setLevel_roundsAndClampsValues() async throws {
        let midTask = subject.dispatch([.setLevel(0.496)])
        try await midTask.result()
        XCTAssertEqual(store.state.level, 50)

        let negativeTask = subject.dispatch([.setLevel(-0.5)])
        try await negativeTask.result()
        XCTAssertEqual(store.state.level, 0)

        let highTask = subject.dispatch([.setLevel(1.75)])
        try await highTask.result()
        XCTAssertEqual(store.state.level, 100)
    }
}

private struct BatteryStoreSnapshot: Decodable, Equatable {
    let isMonitoringEnabled: Bool
    let state: String
    let level: Int
}
