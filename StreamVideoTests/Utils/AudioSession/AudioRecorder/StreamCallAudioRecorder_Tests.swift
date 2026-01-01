//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
@testable import StreamVideo
@preconcurrency import XCTest

final class StreamCallAudioRecorder_Tests: StreamVideoTestCase, @unchecked Sendable {

    private lazy var spyMiddleware: MockMiddleware<StreamCallAudioRecorder.Namespace>! = StreamCallAudioRecorder
        .Namespace
        .mockMiddleware()
    private lazy var store: Store<StreamCallAudioRecorder.Namespace>! = StreamCallAudioRecorder
        .Namespace
        .store(initialState: .initial, middleware: [spyMiddleware])
    private lazy var subject: StreamCallAudioRecorder! = .init(store)

    override func tearDown() {
        subject = nil
        spyMiddleware = nil
        store = nil
        super.tearDown()
    }

    // MARK: - startRecording

    func test_startRecording_ignoreActiveCallFalse_firesExpectedActions() async {
        subject.startRecording(ignoreActiveCall: false)

        await fulfillment { self.spyMiddleware.actionsReceived.endIndex == 1 }
        XCTAssertEqual(spyMiddleware.actionsReceived.first, .setIsRecording(true))
    }

    func test_startRecording_ignoreActiveCallTrue_firesExpectedActions() async {
        subject.startRecording(ignoreActiveCall: true)

        await fulfillment { self.spyMiddleware.actionsReceived.endIndex == 2 }
        XCTAssertEqual(spyMiddleware.actionsReceived.first, .setShouldRecord(true))
        XCTAssertEqual(spyMiddleware.actionsReceived.last, .setIsRecording(true))
    }

    // MARK: - stopRecording

    func test_stopRecording_firesExpectedActions() async {
        subject.stopRecording()

        await fulfillment { self.spyMiddleware.actionsReceived.endIndex == 1 }
        XCTAssertEqual(spyMiddleware.actionsReceived.first, .setIsRecording(false))
    }

    // MARK: isRecording

    func test_isRecording_true_valueWasUpdatedAsExpected() async {
        _ = subject

        store.dispatch(.setIsRecording(true))

        await fulfillment { self.subject.isRecording == true }
    }

    func test_isRecording_trueAndThenFalse_valueWasUpdatedAsExpected() async {

        store.dispatch(.setIsRecording(true))

        await fulfillment { self.subject.isRecording == true }

        store.dispatch(.setIsRecording(false))

        await fulfillment { self.subject.isRecording == false }
    }

    // MARK: - meters

    func test_meters_allValuesWereFetched() async {
        let values: [Float] = [0.2, 0.3, 0.1, 1, 4, 0.5]
        nonisolated(unsafe) var valuesReceived: [Float] = []
        let cancellable = subject
            .$meters
            .dropFirst() // The initial value of 0 is being dropped to avoid noise.
            .sink { valuesReceived.append($0) }

        values.forEach { store.dispatch(.setMeter($0)) }

        await fulfillment { valuesReceived == values }

        cancellable.cancel()
    }
}
