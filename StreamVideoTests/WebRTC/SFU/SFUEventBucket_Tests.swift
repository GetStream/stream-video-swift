//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

final class SFUsubject_Tests: XCTestCase, @unchecked Sendable {

    private lazy var mockSFUStack: MockSFUStack! = MockSFUStack()
    private lazy var subject: SFUEventBucket! = SFUEventBucket(sfuAdapter)
    private var sfuAdapter: SFUAdapter { mockSFUStack.adapter }

    override func tearDown() {
        mockSFUStack = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - consumeEvents

    func test_consumeEvents() async {
        // Given
        _ = subject
        let expectedEvent = Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload.subscriberOffer(.dummy())
        mockSFUStack.receiveEvent(.sfuEvent(expectedEvent))
        await wait(for: 0.5)

        // When
        let consumedEvents = subject
            .consume(Stream_Video_Sfu_Event_SubscriberOffer.self)

        // Then
        XCTAssertEqual(consumedEvents.count, 1)
        XCTAssertEqual(consumedEvents.first, expectedEvent)
    }

    func test_consumeEvents_stopsObservation() async {
        // Given
        _ = subject
        let expectedEvent = Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload.subscriberOffer(.dummy())
        mockSFUStack.receiveEvent(.sfuEvent(expectedEvent))
        await wait(for: 0.5)

        // When
        _ = subject.consume(Stream_Video_Sfu_Event_SubscriberOffer.self)
        mockSFUStack.receiveEvent(.sfuEvent(Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload.subscriberOffer(.dummy())))

        // Then
        let consumedEvents = subject.consume(Stream_Video_Sfu_Event_SubscriberOffer.self)
        XCTAssertEqual(consumedEvents.count, 1)
        XCTAssertEqual(consumedEvents.first, expectedEvent)
    }

    func test_consumeEvents_threadSafety() async {
        // Given
        _ = subject
        let expectedEvent = Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload.subscriberOffer(.dummy())
        let expectation = expectation(description: "Thread safety test")

        // When
        Task {
            self.mockSFUStack.receiveEvent(.sfuEvent(expectedEvent))
            await wait(for: 0.5)
            _ = self.subject.consume(Stream_Video_Sfu_Event_SubscriberOffer.self)
            expectation.fulfill()
        }

        // Then
        await fulfillment(of: [expectation], timeout: 1)
        let consumedEvents = subject.consume(Stream_Video_Sfu_Event_SubscriberOffer.self)
        XCTAssertEqual(consumedEvents.count, 1)
        XCTAssertEqual(consumedEvents.first, expectedEvent)
    }
}
