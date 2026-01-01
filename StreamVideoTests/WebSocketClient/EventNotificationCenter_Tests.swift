//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreData
@testable import StreamVideo
import XCTest

final class EventNotificationCenter_Tests: XCTestCase, @unchecked Sendable {

    func test_init_worksCorrectly() {
        // Create middlewares
        let middlewares: [EventMiddleware_Mock] = [
            .init(),
            .init(),
            .init()
        ]

        // Create notification center with middlewares
        let center = EventNotificationCenter()
        middlewares.forEach(center.add)

        // Assert middlewares are assigned correctly
        let centerMiddlewares = center.middlewares as! [EventMiddleware_Mock]
        XCTAssertEqual(middlewares.count, centerMiddlewares.count)
        zip(middlewares, centerMiddlewares).forEach {
            XCTAssertTrue($0.0 === $0.1)
        }
    }

    func test_addMiddleware_worksCorrectly() {
        // Create middlewares
        let middlewares: [EventMiddleware_Mock] = [
            .init(),
            .init(),
            .init()
        ]

        // Create notification center without any middlewares
        let center = EventNotificationCenter()

        // Add middlewares via `add` method
        middlewares.forEach(center.add)

        // Assert middlewares are assigned correctly
        let centerMiddlewares = center.middlewares as! [EventMiddleware_Mock]
        XCTAssertEqual(middlewares.count, centerMiddlewares.count)
        zip(middlewares, centerMiddlewares).forEach {
            XCTAssertTrue($0.0 === $0.1)
        }
    }

    func test_eventIsNotPublished_ifSomeMiddlewareDoesNotForwardEvent() {
        let consumingMiddleware = EventMiddleware_Mock { _ in nil }

        // Create a notification center with blocking middleware
        let center = EventNotificationCenter()
        center.add(middleware: consumingMiddleware)

        // Create event logger to check published events
        let eventLogger = EventLogger(center)

        // Simulate incoming event
        center.process(.internalEvent(TestEvent()))

        // Assert event is published as it is
        AssertAsync.staysTrue(eventLogger.equatableEvents.isEmpty)
    }

    func test_eventIsPublishedAsItIs_ifThereAreNoMiddlewares() {
        // Create a notification center without any middlewares
        let center = EventNotificationCenter()

        // Create event logger to check published events
        let eventLogger = EventLogger(center)

        // Simulate incoming event
        let event = TestEvent()
        center.process(.internalEvent(event))

        let expectation = expectation(description: "wait expectation")
        expectation.isInverted = true
        wait(for: [expectation], timeout: 1)

        // Assert event is published as it is
        AssertAsync.willBeEqual(eventLogger.events as? [TestEvent], [event])
    }

    func test_process_whenShouldPostEventsIsTrue_eventsArePosted() {
        // Create a notification center with just a forwarding middleware
        let center = EventNotificationCenter()

        // Create event logger to check published events
        let eventLogger = EventLogger(center)

        // Simulate incoming events
        let events = [TestEvent(), TestEvent(), TestEvent(), TestEvent()]

        // Feed events that should be posted and catch the completion
        nonisolated(unsafe) var completionCalled = false
        center.process(events.map { .internalEvent($0) }, postNotifications: true) {
            completionCalled = true
        }

        // Wait completion to be called
        AssertAsync.willBeTrue(completionCalled)

        // Assert events are posted.
        XCTAssertEqual(eventLogger.events as! [TestEvent], events)
    }

    func test_process_whenShouldPostEventsIsFalse_eventsAreNotPosted() {
        // Create a notification center with just a forwarding middleware
        let center = EventNotificationCenter()

        // Create event logger to check published events
        let eventLogger = EventLogger(center)

        // Simulate incoming events
        let events = [TestEvent(), TestEvent(), TestEvent(), TestEvent()]

        // Feed events that should not be posted and catch the completion
        nonisolated(unsafe) var completionCalled = false
        center.process(events.map { .internalEvent($0) }, postNotifications: false) {
            completionCalled = true
        }

        // Wait completion to be called
        AssertAsync.willBeTrue(completionCalled)

        // Assert events are not posted.
        XCTAssertTrue(eventLogger.events.isEmpty)
    }

    func test_process_postsEventsOnPostingQueue() {
        // Create notification center
        let center = EventNotificationCenter()

        // Assign mock events posting queue
        let mockQueueUUID = UUID()
        let mockQueue = DispatchQueue.testQueue(withId: mockQueueUUID)
        center.eventPostingQueue = mockQueue

        // Create test event
        let testEvent = TestEvent()

        // Setup event observer
        nonisolated(unsafe) var observerTriggered = false

        let observer = center.addObserver(
            forName: .NewEventReceived,
            object: nil,
            queue: nil
        ) { notification in
            guard let wrappedEvent = notification.event else { return }

            switch wrappedEvent {
            case let .internalEvent(event):
                // Assert notification contains test event
                XCTAssertEqual(event as? TestEvent, testEvent)
                // Assert notification is posted on correct queue
                XCTAssertTrue(DispatchQueue.isTestQueue(withId: mockQueueUUID))
            default:
                break
            }

            observerTriggered = true
        }

        // Process test event and post when processing is completed
        center.process([.internalEvent(testEvent)], postNotifications: true)

        let expectation = expectation(description: "wait expectation")
        expectation.isInverted = true
        wait(for: [expectation], timeout: 1)

        // Wait for observer to be called
        AssertAsync.willBeTrue(observerTriggered)

        // Remove observer
        center.removeObserver(observer)
    }

    func test_process_whenOriginalEventIsSwapped_newEventIsProcessedFurther() {
        // Create incoming event
        let originalEvent = TestEvent()

        // Create event that will be returned instead of incoming event
        let outputEvent = TestEvent()

        // Create a notification center
        let center = EventNotificationCenter()

        // Create event logger to check published events
        let eventLogger = EventLogger(center)

        // Add event swapping middleware
        center.add(middleware: EventMiddleware_Mock { event in
            // Assert expected event is received
            if case let .internalEvent(event) = event {
                XCTAssertEqual(event as? TestEvent, originalEvent)
                // Swap to outputEvent
                return .internalEvent(outputEvent)
            }
            return event
        })

        // Start processing of original event
        center.process(.internalEvent(originalEvent), postNotification: true)

        let expectation = expectation(description: "wait expectation")
        expectation.isInverted = true
        wait(for: [expectation], timeout: 1)

        // Assert event returned from middleware is posted
        AssertAsync.willBeEqual(
            eventLogger.events.compactMap { $0 as? TestEvent },
            [outputEvent]
        )
    }
}
