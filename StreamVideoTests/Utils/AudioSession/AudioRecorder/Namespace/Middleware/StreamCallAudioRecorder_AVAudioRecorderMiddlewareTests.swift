//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamVideo
import XCTest

final class StreamCallAudioRecorder_AVAudioRecorderMiddlewareTests: StreamVideoTestCase, @unchecked Sendable {

    private var actionsReceived: [(StreamCallAudioRecorder.Namespace.Action, StoreDelay)]! = []
    private var audioRecorder: MockAVAudioRecorder!
    private lazy var mockPermissions: MockPermissionsStore! = .init(inject: false)
    private lazy var mockAudioStore: MockRTCAudioStore! = .init()
    private lazy var subject: StreamCallAudioRecorder
        .Namespace
        .AVAudioRecorderMiddleware! = .init(
            audioRecorder: audioRecorder,
            permissions: mockPermissions.permissionsStore,
            audioStore: mockAudioStore.audioStore
        )

    override func setUp() async throws {
        try await super.setUp()
        _ = mockPermissions
        audioRecorder = try .build()
        _ = subject
    }

    override func tearDown() async throws {
        mockPermissions.dismantle()

        subject = nil
        audioRecorder = nil
        actionsReceived = nil
        try await mockAudioStore.dismantle()
        mockAudioStore = nil
        try await super.tearDown()
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

    /// `isRecording` is the caller's intent. A stopped recording must not
    /// restart when an interruption ends, even if `shouldRecord` is `true`.
    func test_setIsInterruptedFalse_shouldRecordTrueIsRecordingFalse_doesNotStartRecording() async {
        subject.apply(
            state: .init(isRecording: false, isInterrupted: true, shouldRecord: true, meter: 0),
            action: .setIsInterrupted(false),
            file: #file,
            function: #function,
            line: #line
        )

        await wait(for: 0.2)
        XCTAssertEqual(audioRecorder.timesCalled(.record), 0)
    }

    func test_setIsInterruptedFalse_shouldRecordTrueIsRecordingTrue_restartsRecording() async {
        await prepareAsRecording()
        subject.apply(
            state: .init(isRecording: true, isInterrupted: true, shouldRecord: true, meter: 0),
            action: .setIsInterrupted(true),
            file: #file,
            function: #function,
            line: #line
        )
        await fulfillment { self.audioRecorder.timesCalled(.stop) == 1 }

        subject.apply(
            state: .init(isRecording: true, isInterrupted: true, shouldRecord: true, meter: 0),
            action: .setIsInterrupted(false),
            file: #file,
            function: #function,
            line: #line
        )

        await fulfillment { self.audioRecorder.timesCalled(.record) == 2 }
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
        // TODO: REMOVE
        meterExpectation.assertForOverFulfill = false
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

    // MARK: - audioDeviceModule

    func test_init_initialAudioDeviceModuleReport_doesNotRestartRunningRecording() async {
        // The initial report is queued during init. Start recording
        // right after, so a restart on that report would be observable.
        subject = .init(
            audioRecorder: audioRecorder,
            permissions: mockPermissions.permissionsStore,
            audioStore: mockAudioStore.audioStore
        )
        subject.stateProvider = { self.recordingState }
        await prepareAsRecording()

        await wait(for: 0.5)
        XCTAssertEqual(audioRecorder.timesCalled(.record), 1)
        XCTAssertEqual(audioRecorder.timesCalled(.stop), 0)
    }

    func test_audioDeviceModuleChanges_whileRecording_switchesModeEachTime() async throws {
        audioRecorder.stub(for: .record, with: true)
        subject.stateProvider = { self.recordingState }
        await prepareAsRecording()

        // nil -> module: recording moves to the module, recorder stops.
        try await mockAudioStore.audioStore.dispatch(
            .setAudioDeviceModule(.init(MockRTCAudioDeviceModule()))
        ).result()
        await fulfillment { self.audioRecorder.timesCalled(.stop) == 1 }
        await wait(for: 0.2)
        XCTAssertEqual(audioRecorder.timesCalled(.record), 1)

        // module -> nil: recording moves back to the recorder.
        try await mockAudioStore.audioStore.dispatch(
            .setAudioDeviceModule(nil)
        ).result()
        await fulfillment { self.audioRecorder.timesCalled(.record) == 2 }
    }

    // MARK: - Private Helpers

    private var recordingState: StreamCallAudioRecorder.Namespace.State {
        .init(isRecording: true, isInterrupted: false, shouldRecord: true, meter: 0)
    }

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
