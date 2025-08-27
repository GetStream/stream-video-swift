//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamVideo
import XCTest

final class StreamCallAudioRecorder_AVAudioRecorderMiddlewareTests: StreamVideoTestCase, @unchecked Sendable {

    private var actionsReceived: [(StreamCallAudioRecorder.Namespace.Action, Store<StreamCallAudioRecorder.Namespace>.Delay)]! = []
    private var audioRecorder: MockAVAudioRecorder!
    private lazy var mockPermissions: MockPermissionsStore! = .init()
    private lazy var subject: StreamCallAudioRecorder
        .Namespace
        .AVAudioRecorderMiddleware! = .init(audioRecorder: audioRecorder)

    override func setUp() async throws {
        try await super.setUp()
        _ = mockPermissions
        audioRecorder = try .build()
        _ = subject
    }

    override func tearDown() {
        mockPermissions.dismantle()
        
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
        let validation = expectation(description: "Dispatcher was called.")
        subject.dispatcher = .init { action, _, _, _, _ in
            switch action {
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
        subject.dispatcher = .init { action, _, _, _, _ in
            switch action {
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

    func test_setShouldRecordTrue_isRecordingFalse_requestRecordPermissionWasCalled() async {
        subject.apply(
            state: .init(isRecording: false, isInterrupted: true, shouldRecord: true, meter: 0),
            action: .setShouldRecord(true),
            file: #file,
            function: #function,
            line: #line
        )

        await fulfillment { self.mockPermissions.timesCalled(.requestMicrophonePermission) == 1 }
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
