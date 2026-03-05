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
        StreamVideoProviderKey.currentValue = nil
        InjectedValues[\.callCache].removeAll()

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

    func test_updateMetadata_whenMetadataChanges_recordsMetadataUpdatedEvent()
    throws {
        let fixedUUID = UUID(uuidString: "A5A2CEAE-8FD9-4C4D-913A-5A86D8F0979E")!

        subject = .init(
            type: TokenTrackedType.self,
            metadata: ["key": "value-1"],
            observer: recorder,
            uuidFactory: StaticUUIDFactory(fixedUUID)
        )

        subject?.updateMetadata(["key": "value-2"])

        let updatedEvent = try XCTUnwrap(
            recorder.events(
                for: TokenTrackedType.self,
                transition: .metadataUpdated,
                metadata: ["key": "value-2"]
            ).first
        )
        XCTAssertEqual(updatedEvent.instanceId, fixedUUID.uuidString)
    }

    func test_updateMetadata_whenMetadataIsUnchanged_doesNotRecordEvent() {
        subject = .init(
            type: TokenTrackedType.self,
            metadata: ["key": "value"],
            observer: recorder
        )

        subject?.updateMetadata(["key": "value"])

        XCTAssertTrue(
            recorder.events(
                for: TokenTrackedType.self,
                transition: .metadataUpdated
            ).isEmpty
        )
    }

    func test_updateMetadataForStreamVideo_whenCalled_recordsMetadataUpdatedEvent()
    throws {
        let fixedUUID = UUID(uuidString: "A5A2CEAE-8FD9-4C4D-913A-5A86D8F0979E")!
        let streamVideo = StreamVideo.mock(httpClient: HTTPClient_Mock())
        let expectedMetadata = [
            "user.id": streamVideo.user.id,
            "user.name": streamVideo.user.name,
            "stream.connection.id": streamVideo.connectionId ?? "-"
        ]

        subject = .init(
            type: TokenTrackedType.self,
            observer: recorder,
            uuidFactory: StaticUUIDFactory(fixedUUID)
        )
        subject?.updateMetadata(for: streamVideo)

        let updatedEvent = try XCTUnwrap(
            recorder.events(
                for: TokenTrackedType.self,
                transition: .metadataUpdated,
                metadata: expectedMetadata
            ).first
        )
        XCTAssertEqual(updatedEvent.instanceId, fixedUUID.uuidString)
    }

    @MainActor
    func test_updateMetadataForCall_whenCalled_recordsMetadataUpdatedEvent() throws {
        let fixedUUID = UUID(uuidString: "A5A2CEAE-8FD9-4C4D-913A-5A86D8F0979E")!
        let streamVideo = StreamVideo.mock(httpClient: HTTPClient_Mock())
        let call = streamVideo.call(callType: "default", callId: String.unique)
        let expectedMetadata = [
            "session.id": call.state.sessionId,
            "user.id": streamVideo.user.id,
            "user.name": streamVideo.user.name,
            "stream.connection.id": streamVideo.connectionId ?? "-"
        ]

        subject = .init(
            type: TokenTrackedType.self,
            observer: recorder,
            uuidFactory: StaticUUIDFactory(fixedUUID)
        )
        subject?.updateMetadata(for: call)

        let updatedEvent = try XCTUnwrap(
            recorder.events(
                for: TokenTrackedType.self,
                transition: .metadataUpdated,
                metadata: expectedMetadata
            ).first
        )
        XCTAssertEqual(updatedEvent.instanceId, fixedUUID.uuidString)
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
