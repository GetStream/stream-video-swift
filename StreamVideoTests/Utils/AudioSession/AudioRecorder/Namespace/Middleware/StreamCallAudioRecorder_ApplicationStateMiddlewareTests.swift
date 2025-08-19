//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class StreamCallAudioRecorder_ApplicationStateMiddlewareTests: StreamVideoTestCase, @unchecked Sendable {

    private var mockApplicationStateAdapter: MockAppStateAdapter! = .init()
    private var actionsReceived: [(StreamCallAudioRecorder.Namespace.Action, Store<StreamCallAudioRecorder.Namespace>.Delay)] = []
    private lazy var subject: StreamCallAudioRecorder
        .Namespace
        .ApplicationStateMiddleware! = .init()

    override func setUp() {
        super.setUp()
        mockApplicationStateAdapter.makeShared()
        _ = subject
    }

    override func tearDown() {
        subject = nil
        mockApplicationStateAdapter = nil
        super.tearDown()
    }

    // MARK: - applicationState updated

    func test_applicationStateUpdated_isRecordingFalse_noActionWasDispatched() async throws {
        let validation = expectation(description: "Dispatcher was called")
        validation.isInverted = true
        subject.stateProvider = { .initial }
        subject.dispatcher = .init { _, _, _, _, _ in }

        mockApplicationStateAdapter.stubbedState = .background

        await safeFulfillment(of: [validation], timeout: 1)
    }

    func test_applicationStateUpdated_isRecordingTrue_dispatchesActionsAsExpected() async throws {
        _ = subject
        await wait(for: 1.0) // We wait for the initial setup to occur
        subject.stateProvider = {
            .init(
                isRecording: true,
                isInterrupted: false,
                shouldRecord: false,
                meter: 0
            )
        }

        subject.dispatcher = .init { action, delay, _, _, _ in
            self.actionsReceived.append((action, delay))
        }

        mockApplicationStateAdapter.stubbedState = .background
        await fulfillment { self.actionsReceived.endIndex == 2 }

        let firstEntry = try XCTUnwrap(actionsReceived.first)
        let secondEntry = try XCTUnwrap(actionsReceived.last)

        XCTAssertEqual(firstEntry.0, .setIsRecording(false))
        XCTAssertEqual(firstEntry.1, .none())
        XCTAssertEqual(secondEntry.0, .setIsRecording(true))
        XCTAssertEqual(secondEntry.1, .init(before: 0.25))
    }
}
