//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

final class WebRTCSFUFullObserver_Tests: XCTestCase, @unchecked Sendable {
    private var cancellables: Set<AnyCancellable> = []
    private lazy var sfuStack: MockSFUStack! = .init()
    private lazy var subject: WebRTCSFUFullObserver! = .init(sfuStack.adapter)

    // MARK: - Lifecycle

    override func tearDown() {
        cancellables = []
        subject = nil
        sfuStack = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init_setsHostnameAndInitialState() {
        XCTAssertEqual(subject.hostname, sfuStack.adapter.hostname)
        XCTAssertNil(subject.shouldMigrateError)
    }

    // MARK: - publisher

    func test_publisher_whenSFUFullErrorReceived_emitsTheErrorPayload() async throws {
        let transitionExpectation = expectation(description: "Observer should emit SFU_FULL payload.")

        subject
            .publisher
            .sink { error in
                if error.error.code == .sfuFull {
                    transitionExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        var error = Stream_Video_Sfu_Event_Error()
        error.error.code = .sfuFull
        sfuStack.receiveEvent(.sfuEvent(.error(error)))

        await fulfillment(of: [transitionExpectation], timeout: defaultTimeout)
        XCTAssertEqual(try XCTUnwrap(subject.shouldMigrateError).error.code, .sfuFull)
    }

    func test_publisher_whenErrorCodeIsNotSFUFull_doesNotEmitOrUpdateState() async {
        var error = Stream_Video_Sfu_Event_Error()
        error.error.code = .participantSignalLost
        sfuStack.receiveEvent(.sfuEvent(.error(error)))

        await wait(for: 0.2)
        XCTAssertNil(subject.shouldMigrateError)
    }
}
