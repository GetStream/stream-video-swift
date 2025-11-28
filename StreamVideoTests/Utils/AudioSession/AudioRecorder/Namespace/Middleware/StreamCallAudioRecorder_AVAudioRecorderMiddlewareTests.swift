//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamVideo
import XCTest

final class StreamCallAudioRecorder_AVAudioRecorderMiddlewareTests: StreamVideoTestCase, @unchecked Sendable {

    private var actionsReceived: [(StreamCallAudioRecorder.Namespace.Action, StoreDelay)]! = []
    private var audioRecorder: MockAVAudioRecorder!
    private lazy var mockPermissions: MockPermissionsStore! = .init()
    private lazy var mockAudioStore: MockRTCAudioStore! = .init()
    private lazy var subject: StreamCallAudioRecorder
        .Namespace
        .AVAudioRecorderMiddleware! = .init(audioRecorder: audioRecorder)

    override func setUp() async throws {
        try await super.setUp()
        mockAudioStore.makeShared()
        _ = mockPermissions
        audioRecorder = try .build()
        _ = subject
    }

    override func tearDown() {
        mockPermissions.dismantle()
        mockAudioStore.dismantle()

        subject = nil
        audioRecorder = nil
        actionsReceived = nil
        super.tearDown()
    }

    // MARK: - setIsRecording

    func test_setIsRecordingTrue_shouldRecordFalse_requestRecordPermissionWasNotCalled() async {
        subject.apply(
            state: .init(isRecording: false, isInterrupted: false, shouldRecord: false, meter: 0),
            action: .setIsRecording(true),
            file: #file,
            function: #function,
            line: #line
        )

        await wait(for: 0.1)
        XCTAssertEqual(mockPermissions.timesCalled(.requestMicrophonePermission), 0)
    }

    func test_setIsRecordingTrue_shouldRecordTrue_isMeteringEnabledShouldBeSetToTrue() async {
        subject.apply(
            state: .init(isRecording: false, isInterrupted: false, shouldRecord: true, meter: 0),
            action: .setIsRecording(true),
            file: #file,
            function: #function,
            line: #line
        )

        await fulfillment { self.audioRecorder.isMeteringEnabled == true }
    }

    func test_setIsRecordingTrue_shouldRecordTrue_requestRecordPermissionWasCalled() async {
        mockPermissions.stubMicrophonePermission(.unknown)
        await fulfillment { self.mockPermissions.mockStore.state.microphonePermission == .unknown }

        subject.apply(
            state: .init(isRecording: false, isInterrupted: false, shouldRecord: true, meter: 0),
            action: .setIsRecording(true),
            file: #file,
            function: #function,
            line: #line
        )

        await fulfillment {
            self.mockPermissions.timesCalled(.requestMicrophonePermission) == 1
        }
    }

    func test_setIsRecordingTrue_shouldRecordTrueRequestRecordPermissionFalse_isMeteringEnabledShouldBeSetToFalse() async {
        mockPermissions.stubMicrophonePermission(.denied)
        await fulfillment { self.mockPermissions.mockStore.state.microphonePermission == .denied }
        let validation = expectation(description: "Dispatcher was called.")
        subject.dispatcher = .init { actions, _, _, _ in
            switch actions[0].wrappedValue {
            case let .setIsRecording(value) where value == false:
                validation.fulfill()
            default:
                break
            }
        }
        subject.apply(
            state: .init(isRecording: false, isInterrupted: false, shouldRecord: true, meter: 0),
            action: .setIsRecording(true),
            file: #file,
            function: #function,
            line: #line
        )

        await safeFulfillment(of: [validation])
        await fulfillment { self.audioRecorder.isMeteringEnabled == false }
    }

    func test_setIsRecordingTrue_shouldRecordTrueRequestRecordPermissionTrue_recordWasCalled() async {
        subject.apply(
            state: .init(isRecording: false, isInterrupted: false, shouldRecord: true, meter: 0),
            action: .setIsRecording(true),
            file: #file,
            function: #function,
            line: #line
        )

        await fulfillment { self.audioRecorder.timesCalled(.record) == 1 }
    }

    func test_setIsRecordingTrue_shouldRecordTrueRequestRecordPermissionTrueRecordFalse_isMeteringEnabledShouldBeSetToFalse() async {
        audioRecorder.stub(for: .record, with: false)
        let validation = expectation(description: "Dispatcher was called.")
        subject.dispatcher = .init { actions, _, _, _ in
            switch actions[0].wrappedValue {
            case let .setIsRecording(value) where value == false:
                validation.fulfill()
            default:
                break
            }
        }
        subject.apply(
            state: .init(isRecording: false, isInterrupted: false, shouldRecord: true, meter: 0),
            action: .setIsRecording(true),
            file: #file,
            function: #function,
            line: #line
        )

        await safeFulfillment(of: [validation])
        await fulfillment { self.audioRecorder.isMeteringEnabled == false }
    }

    func test_setIsRecordingTrue_shouldRecordTrueRequestRecordPermissionTrueRecordTrue_observesMeters() async {
        audioRecorder.stub(for: .record, with: true)
        subject.apply(
            state: .init(isRecording: false, isInterrupted: false, shouldRecord: true, meter: 0),
            action: .setIsRecording(true),
            file: #file,
            function: #function,
            line: #line
        )

        await fulfillment { self.audioRecorder.timesCalled(.updateMeters) > 2 }
    }

    func test_setIsRecordingFalse_callsStopOnRecordingAndIsMeteringEnabledFalse() async {
        await prepareAsRecording()

        subject.apply(
            state: .init(isRecording: true, isInterrupted: false, shouldRecord: true, meter: 0),
            action: .setIsRecording(false),
            file: #file,
            function: #function,
            line: #line
        )

        await fulfillment {
            self.audioRecorder.timesCalled(.stop) == 1
                && self.audioRecorder.isMeteringEnabled == false
        }

        XCTAssertEqual(audioRecorder.timesCalled(.stop), 1)
        XCTAssertFalse(audioRecorder.isMeteringEnabled)
    }

    func test_setIsRecordingTrue_calledTwice_restartsRecorderOnce() async {
        // First start
        audioRecorder.stub(for: .record, with: true)
        subject.apply(
            state: .init(isRecording: false, isInterrupted: false, shouldRecord: true, meter: 0),
            action: .setIsRecording(true),
            file: #file,
            function: #function,
            line: #line
        )
        await fulfillment { self.audioRecorder.timesCalled(.record) == 1 }

        // Second start should call stop before recording again
        subject.apply(
            state: .init(isRecording: false, isInterrupted: false, shouldRecord: true, meter: 0),
            action: .setIsRecording(true),
            file: #file,
            function: #function,
            line: #line
        )

        await fulfillment {
            self.audioRecorder.timesCalled(.stop) >= 1
                && self.audioRecorder.timesCalled(.record) >= 2
        }
    }

    // MARK: - setIsInterrupted

    func test_setIsInterruptedTrue_whileRecording_stopsRecording() async {
        await prepareAsRecording()

        subject.apply(
            state: .init(isRecording: true, isInterrupted: false, shouldRecord: true, meter: 0),
            action: .setIsInterrupted(true),
            file: #file,
            function: #function,
            line: #line
        )

        await fulfillment {
            self.audioRecorder.timesCalled(.stop) == 1
                && self.audioRecorder.isMeteringEnabled == false
        }
    }

    func test_setIsInterruptedFalse_shouldRecordFalse_requestRecordPermissionWasNotCalled() async {
        subject.apply(
            state: .init(isRecording: true, isInterrupted: true, shouldRecord: false, meter: 0),
            action: .setIsInterrupted(false),
            file: #file,
            function: #function,
            line: #line
        )

        await wait(for: 0.1)
        XCTAssertEqual(mockPermissions.timesCalled(.requestMicrophonePermission), 0)
    }

    func test_setIsInterruptedFalse_shouldRecordTrueIsRecordingTrue_requestRecordPermissionWasNotCalled() async {
        subject.apply(
            state: .init(isRecording: true, isInterrupted: true, shouldRecord: true, meter: 0),
            action: .setIsInterrupted(false),
            file: #file,
            function: #function,
            line: #line
        )

        await wait(for: 0.1)
        XCTAssertEqual(mockPermissions.timesCalled(.requestMicrophonePermission), 0)
    }

    func test_setIsInterruptedFalse_shouldRecordTrueIsRecordingFalse_requestRecordPermissionWasCalled() async {
        mockPermissions.stubMicrophonePermission(.unknown)
        await fulfillment { self.mockPermissions.mockStore.state.microphonePermission == .unknown }

        subject.apply(
            state: .init(isRecording: false, isInterrupted: true, shouldRecord: true, meter: 0),
            action: .setIsInterrupted(false),
            file: #file,
            function: #function,
            line: #line
        )

        await fulfillment { self.mockPermissions.timesCalled(.requestMicrophonePermission) == 1 }
    }

    // MARK: - setShouldRecord

    func test_setShouldRecordTrue_isRecordingTrue_requestRecordPermissionWasNotCalled() async {
        subject.apply(
            state: .init(isRecording: true, isInterrupted: true, shouldRecord: true, meter: 0),
            action: .setShouldRecord(true),
            file: #file,
            function: #function,
            line: #line
        )

        await wait(for: 0.1)
        XCTAssertEqual(mockPermissions.timesCalled(.requestMicrophonePermission), 0)
    }

    func test_setShouldRecordFalse_isRecordingTrue_stopWasCalled() async {
        await prepareAsRecording()

        subject.apply(
            state: .init(isRecording: true, isInterrupted: true, shouldRecord: true, meter: 0),
            action: .setShouldRecord(false),
            file: #file,
            function: #function,
            line: #line
        )

        await fulfillment {
            self.audioRecorder.timesCalled(.stop) == 1
                && self.audioRecorder.isMeteringEnabled == false
        }
    }

    func test_setShouldRecordFalse_whenNotRecording_doesNotCallStop() async {
        subject.apply(
            state: .init(isRecording: false, isInterrupted: false, shouldRecord: false, meter: 0),
            action: .setShouldRecord(false),
            file: #file,
            function: #function,
            line: #line
        )

        await wait(for: 0.2)
        XCTAssertEqual(audioRecorder.timesCalled(.stop), 0)
    }

    func test_setIsRecordingTrue_dispatchesSetMeterValues() async {
        audioRecorder.stub(for: .record, with: true)
        let meterExpectation = expectation(description: "meter updates")
        meterExpectation.expectedFulfillmentCount = 2
        subject.dispatcher = .init { actions, _, _, _ in
            if case .setMeter = actions.first?.wrappedValue { meterExpectation.fulfill() }
        }

        subject.apply(
            state: .init(isRecording: false, isInterrupted: false, shouldRecord: true, meter: 0),
            action: .setIsRecording(true),
            file: #file,
            function: #function,
            line: #line
        )

        await safeFulfillment(of: [meterExpectation])
    }

    // MARK: - Private Helpers

    private func prepareAsRecording() async {
        audioRecorder.stub(for: .record, with: true)
        subject.apply(
            state: .init(isRecording: false, isInterrupted: false, shouldRecord: true, meter: 0),
            action: .setIsRecording(true),
            file: #file,
            function: #function,
            line: #line
        )

        await fulfillment { self.audioRecorder.timesCalled(.record) == 1 }
    }
}
