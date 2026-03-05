//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class ObjectLifecycleRecorder_Tests: XCTestCase, @unchecked Sendable {

    private var previousLifecycleObserver: ObjectLifecycle.Observing!
    private var subject: ObjectLifecycle.Recorder!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        previousLifecycleObserver = InjectedValues[\.objectLifecycleObserver]
        subject = .init()
        InjectedValues[\.objectLifecycleObserver] = subject
    }

    override func tearDown() {
        InjectedValues[\.objectLifecycleObserver] = previousLifecycleObserver
        previousLifecycleObserver = nil

        StreamVideoProviderKey.currentValue = nil
        InjectedValues[\.callCache].removeAll()

        subject = nil
        super.tearDown()
    }

    // MARK: - record(_:)

    func test_record_whenTrackingTransitions_updatesCountsAndLiveCount() {
        subject.record(event(type: TypeA.self, id: "1", transition: .initialized))
        subject.record(event(type: TypeA.self, id: "2", transition: .initialized))
        subject.record(event(type: TypeA.self, id: "1", transition: .deinitialized))

        XCTAssertEqual(subject.initializedCount(for: TypeA.self), 2)
        XCTAssertEqual(subject.deinitializedCount(for: TypeA.self), 1)
        XCTAssertEqual(subject.liveCount(for: TypeA.self), 1)
    }

    func test_record_whenMetadataUpdated_doesNotChangeCountersOrLiveCount() {
        subject.record(event(type: TypeA.self, id: "1", transition: .initialized))
        subject.record(
            event(
                type: TypeA.self,
                id: "1",
                transition: .metadataUpdated,
                metadata: ["label": "updated"]
            )
        )

        XCTAssertEqual(subject.initializedCount(for: TypeA.self), 1)
        XCTAssertEqual(subject.deinitializedCount(for: TypeA.self), 0)
        XCTAssertEqual(subject.liveCount(for: TypeA.self), 1)
        XCTAssertEqual(
            subject.events(
                for: TypeA.self,
                transition: .metadataUpdated,
                metadata: ["label": "updated"]
            ).count,
            1
        )
    }

    // MARK: - events(...)

    func test_events_whenFilteredByTypeTransitionAndMetadata_returnsMatches() {
        subject.record(
            event(
                type: TypeA.self,
                id: "1",
                transition: .initialized,
                metadata: ["label": "alpha"]
            )
        )
        subject.record(
            event(
                type: TypeA.self,
                id: "2",
                transition: .deinitialized,
                metadata: ["label": "beta"]
            )
        )

        let matches = subject.events(
            for: TypeA.self,
            transition: .initialized,
            metadata: ["label": "alpha"]
        )

        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first?.instanceId, "1")
    }

    // MARK: - isAlive(for:instanceId:)

    func test_isAlive_whenInstanceTransitions_reflectsCurrentState() {
        subject.record(event(type: TypeA.self, id: "1", transition: .initialized))
        XCTAssertTrue(subject.isAlive(for: TypeA.self, instanceId: "1"))

        subject.record(event(type: TypeA.self, id: "1", transition: .deinitialized))
        XCTAssertFalse(subject.isAlive(for: TypeA.self, instanceId: "1"))
    }

    // MARK: - maxStoredEvents

    func test_init_whenMaxStoredEventsExceeded_keepsNewestEvents() {
        let subject = ObjectLifecycle.Recorder(maxStoredEvents: 2)

        subject.record(event(type: TypeA.self, id: "1", transition: .initialized))
        subject.record(event(type: TypeA.self, id: "2", transition: .initialized))
        subject.record(event(type: TypeA.self, id: "3", transition: .initialized))

        let ids = subject.events().map(\.instanceId)
        XCTAssertEqual(ids, ["2", "3"])
    }

    // MARK: - reset()

    func test_reset_whenCalled_clearsState() {
        subject.record(event(type: TypeA.self, id: "1", transition: .initialized))
        XCTAssertEqual(subject.liveCount(for: TypeA.self), 1)

        subject.reset()

        XCTAssertEqual(subject.liveCount(for: TypeA.self), 0)
        XCTAssertTrue(subject.events().isEmpty)
    }

    // MARK: - SDK integration

    func test_lifecycleTracking_whenUsedByStreamVideoAndCall_recordsEvents() {
        let userId = StreamVideo.mockUser.id
        let callType = "default"
        let callId = String.unique
        let cId = callCid(from: callId, callType: callType)

        var streamVideo: StreamVideo? = StreamVideo.mock(httpClient: HTTPClient_Mock())
        AssertAsync.willTrackLifecycleEvent(
            .initialized,
            recorder: subject,
            for: StreamVideo.self,
            metadata: ["user.id": userId]
        )

        var call: Call? = streamVideo?.call(callType: callType, callId: callId)
        XCTAssertNotNil(call)
        AssertAsync.willTrackLifecycleEvent(
            .initialized,
            recorder: subject,
            for: Call.self,
            instanceId: cId
        )

        InjectedValues[\.callCache].removeAll()
        call = nil
        AssertAsync.willTrackLifecycleEvent(
            .deinitialized,
            recorder: subject,
            for: Call.self,
            instanceId: cId
        )

        StreamVideoProviderKey.currentValue = nil
        streamVideo = nil
        AssertAsync.willTrackLifecycleEvent(
            .deinitialized,
            recorder: subject,
            for: StreamVideo.self,
            metadata: ["user.id": userId]
        )
    }

    private func event(
        type: Any.Type,
        id: String,
        transition: ObjectLifecycle.Transition,
        metadata: [String: String] = [:]
    ) -> ObjectLifecycle.Event {
        .init(
            transition: transition,
            typeName: String(reflecting: type),
            instanceId: id,
            timestamp: .distantPast,
            metadata: metadata
        )
    }
}

private enum TypeA {}
