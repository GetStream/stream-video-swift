//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class ObjectLifecycleToken_Tests: XCTestCase, @unchecked Sendable {

    private var subject: ObjectLifecycle.Token?
    private var recorder: ObjectLifecycle.Recorder!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        recorder = .init()
    }

    override func tearDown() {
        subject = nil
        recorder = nil
        super.tearDown()
    }

    // MARK: - init / deinit

    func test_init_whenCreated_recordsInitializationEvent() {
        let fixedDate = Date(timeIntervalSince1970: 1)
        let fixedUUID = UUID(uuidString: "A5A2CEAE-8FD9-4C4D-913A-5A86D8F0979E")!

        subject = .init(
            type: TokenTrackedType.self,
            metadata: ["key": "value"],
            observer: recorder,
            uuidFactory: StaticUUIDFactory(fixedUUID),
            dateProvider: { fixedDate }
        )

        let event = recorder.events(
            for: TokenTrackedType.self,
            transition: .initialized,
            metadata: ["key": "value"]
        ).first

        XCTAssertEqual(event?.instanceId, fixedUUID.uuidString)
        XCTAssertEqual(event?.timestamp, fixedDate)
    }

    func test_deinit_whenReleased_recordsDeinitializationEvent() throws {
        subject = .init(type: TokenTrackedType.self, observer: recorder)

        let initializedId = try XCTUnwrap(
            recorder.events(for: TokenTrackedType.self, transition: .initialized)
                .first?.instanceId
        )

        subject = nil

        AssertAsync.willTrackLifecycleEvent(
            .deinitialized,
            recorder: recorder,
            for: TokenTrackedType.self,
            instanceId: initializedId
        )
    }
}

private enum TokenTrackedType {}

private struct StaticUUIDFactory: UUIDProviding {
    private let uuid: UUID

    init(_ uuid: UUID) {
        self.uuid = uuid
    }

    func get() -> UUID {
        uuid
    }
}
