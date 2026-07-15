//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamCore
@testable import StreamVideo
import XCTest

final class WSEventsMiddleware_Tests: XCTestCase, @unchecked Sendable {

    private var subject: WSEventsMiddleware!

    override func setUp() {
        super.setUp()
        subject = WSEventsMiddleware()
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func test_handle_wrappedEvent_fansOutToAllSubscribers() {
        let expectation = expectation(description: "All subscribers")
        expectation.expectedFulfillmentCount = 2
        let first = SubscriberSpy { _ in expectation.fulfill() }
        let second = SubscriberSpy { _ in expectation.fulfill() }
        subject.add(subscriber: first)
        subject.add(subscriber: second)

        _ = subject.handle(event: makeEvent())

        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_handle_wrappedEvent_notifiesStreamVideoLast() {
        let recorder = Recorder<String>()
        let expectation = expectation(description: "All subscribers")
        expectation.expectedFulfillmentCount = 2
        let streamVideo = StreamVideo(
            apiKey: "key",
            user: .anonymous,
            token: StreamVideo.mockToken,
            videoConfig: .dummy(),
            autoConnectOnInit: false
        )
        let subscriber = SubscriberSpy { _ in
            recorder.append("subscriber")
            expectation.fulfill()
        }
        let cancellable = streamVideo.eventPublisher().sink { _ in
            recorder.append("streamVideo")
            expectation.fulfill()
        }
        subject.add(subscriber: streamVideo)
        subject.add(subscriber: subscriber)

        _ = subject.handle(event: makeEvent())

        wait(for: [expectation], timeout: defaultTimeout)
        XCTAssertEqual(recorder.values, ["subscriber", "streamVideo"])
        cancellable.cancel()
    }

    func test_process_consumedEvent_doesNotNotifySubscribers() {
        let expectation = expectation(description: "No subscriber")
        expectation.isInverted = true
        let subscriber = SubscriberSpy { _ in expectation.fulfill() }
        subject.add(subscriber: subscriber)
        let center = DefaultEventNotificationCenter()
        center.add(middlewares: [ConsumingMiddleware(), subject])

        center.process(makeEvent(), postNotification: false)

        wait(for: [expectation], timeout: 0.1)
    }

    func test_process_sharedCenter_deliversCoordinatorEventOnce() {
        let recorder = Recorder<WrappedEvent>()
        let expectation = expectation(description: "Coordinator event")
        let subscriber = SubscriberSpy {
            recorder.append($0)
            expectation.fulfill()
        }
        subject.add(subscriber: subscriber)
        let center = DefaultEventNotificationCenter()
        center.add(middlewares: [subject])

        center.process(makeEvent(), postNotification: false)

        wait(for: [expectation], timeout: defaultTimeout)
        AssertAsync.staysTrue(recorder.values.count == 1)
    }

    func test_handle_internalConnectionEvents_notifiesSubscribers() {
        let recorder = Recorder<String>()
        let expectation = expectation(description: "Connection events")
        expectation.expectedFulfillmentCount = 2
        let subscriber = SubscriberSpy { event in
            recorder.append(event.name)
            expectation.fulfill()
        }
        subject.add(subscriber: subscriber)

        _ = subject.handle(event: WrappedEvent.internalEvent(WSConnected()))
        _ = subject.handle(event: WrappedEvent.internalEvent(WSDisconnected()))

        wait(for: [expectation], timeout: defaultTimeout)
        XCTAssertEqual(
            recorder.values,
            ["internal: WSConnected", "internal: WSDisconnected"]
        )
    }

    private func makeEvent() -> WrappedEvent {
        .coordinatorEvent(
            .typeHealthCheckEvent(
                .init(
                    connectionId: UUID().uuidString,
                    createdAt: Date()
                )
            )
        )
    }
}

private final class SubscriberSpy: WSEventsSubscriber, @unchecked Sendable {
    private let handler: @Sendable (WrappedEvent) -> Void

    init(handler: @escaping @Sendable (WrappedEvent) -> Void) {
        self.handler = handler
    }

    func onEvent(_ event: WrappedEvent) async {
        handler(event)
    }
}

private struct ConsumingMiddleware: EventMiddleware {
    func handle(event: StreamCore.Event) -> StreamCore.Event? {
        nil
    }
}

private final class Recorder<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [Value] = []

    var values: [Value] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func append(_ value: Value) {
        lock.lock()
        defer { lock.unlock() }
        storage.append(value)
    }
}
