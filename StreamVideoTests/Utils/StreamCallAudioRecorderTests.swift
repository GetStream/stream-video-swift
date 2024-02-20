//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
@testable import StreamVideo
import XCTest

final class StreamAudioRecorderTests: XCTestCase {

    private lazy var builder: AVAudioRecorderBuilder! = .init(cachedResult: mockAudioRecorder)
    private lazy var mockAudioSession: MockAudioSession! = .init()
    private lazy var mockActiveCallProvider: MockStreamActiveCallProvider! = .init()
    private var mockAudioRecorder: MockAudioRecorder!
    private lazy var subject: StreamCallAudioRecorder! = .init(
        audioRecorderBuilder: builder,
        audioSession: mockAudioSession
    )

    override func setUp() async throws {
        try await super.setUp()
        StreamActiveCallProviderKey.currentValue = mockActiveCallProvider
        mockAudioRecorder = try .init(
            url: URL(string: "test.wav")!,
            settings: AVAudioRecorderBuilder.defaultRecordingSettings
        )
    }

    override func tearDown() {
        builder = nil
        mockAudioSession = nil
        mockActiveCallProvider = nil
        mockAudioRecorder = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - init

    func testInitWithFilename_givenValidFilename_whenInitialized_thenSetsUpCorrectly() async throws {
        let filename = "test_recording.m4a"
        let recorder = StreamCallAudioRecorder(filename: filename)

        let actualFileURL = await recorder.audioRecorderBuilder.fileURL.lastPathComponent
        XCTAssertTrue(actualFileURL == filename)
        XCTAssertTrue(recorder.audioSession === AVAudioSession.sharedInstance())
    }

    func testInitWithBuilderAndSession_givenCustomBuilderAndSession_whenInitialized_thenUsesProvidedObjects() {
        XCTAssertTrue(subject.audioRecorderBuilder === builder)
        XCTAssertTrue(subject.audioSession === mockAudioSession)
    }

    // MARK: - deinit

    func testFileDeletion_givenRecordingExists_whenDeinitialized_thenDeletesFile() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory

        let filename = tempDirectory.appendingPathComponent("test_recording.m4a")
        let mockBuilder = AVAudioRecorderBuilder(cachedResult: try .init(url: filename, settings: [:]))
        var recorder: StreamCallAudioRecorder! = StreamCallAudioRecorder(
            audioRecorderBuilder: mockBuilder,
            audioSession: MockAudioSession()
        )

        await recorder.startRecording() // Simulate recording
        recorder = nil

        XCTAssertFalse(FileManager.default.fileExists(atPath: filename.standardizedFileURL.absoluteString))
    }

    // MARK: - startRecording

    func testStartRecording_givenPermissionNotGranted_whenStarted_thenRecordsAndMetersAreNotUpdated() async throws {
        mockAudioSession.recordPermission = false
        await setUpHasActiveCall(true)

        await subject.startRecording()

        try await assertRecording(false, isMeteringEnabled: false)
    }

    func testStartRecording_givenPermissionGranted_whenStarted_thenRecordsAndMetersUpdates() async throws {
        mockAudioSession.recordPermission = true
        await setUpHasActiveCall(true)

        await subject.startRecording()

        try await assertRecording(true)
    }

    func testStartRecording_givenPermissionGrantedButNoActiveCall_whenStarted_thenRecordsAndMetersWontStart() async throws {
        mockAudioSession.recordPermission = true

        await subject.startRecording()

        try await assertRecording(false, isMeteringEnabled: false)
    }

    func testStartRecording_givenPermissionGrantedButNoActiveCall_whenIgnoreActiveCallAndStarted_thenRecordsAndMetersUpdates(
    ) async throws {
        mockAudioSession.recordPermission = true

        await subject.startRecording(ignoreActiveCall: true)

        try await assertRecording(true)
    }

    // MARK: - stopRecording

    func testStopRecording_givenRecording_whenStopped_thenStopsRecording() async throws {
        mockAudioSession.recordPermission = true
        await setUpHasActiveCall(true)

        await subject.startRecording()
        await subject.stopRecording()

        try await assertRecording(false)
    }

    // MARK: - activeCall ended

    func test_activeCallEnded_givenAnActiveCallAndRecordingTrue_whenActiveCallEnds_thenStopsRecording() async throws {
        mockAudioSession.recordPermission = true
        await setUpHasActiveCall(true)
        await subject.startRecording()
        
        await setUpHasActiveCall(false)

        try await assertRecording(false)
    }

    // MARK: - activeCall ended and a new one started

    func test_activeCallEnded_givenAnActiveCallAndRecordingTrue_whenActiveCallEndsAndAnotherOneStarts_thenStartsRecording(
    ) async throws {
        mockAudioSession.recordPermission = true
        await setUpHasActiveCall(true)
        await subject.startRecording()
        await setUpHasActiveCall(false)

        try await assertRecording(false)
        await setUpHasActiveCall(true)
        await subject.startRecording()

        try await assertRecording(true)
    }

    // MARK: - Private Helpers

    private func assertRecording(
        _ isRecording: Bool,
        isMeteringEnabled: Bool = true,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let audioRecorder = try await XCTAsyncUnwrap(await builder.result)
        XCTAssertEqual(
            audioRecorder.isRecording,
            isRecording,
            file: file,
            line: line
        )
        XCTAssertEqual(
            audioRecorder.isMeteringEnabled,
            isMeteringEnabled,
            file: file,
            line: line
        )
        XCTAssertEqual(
            subject.updateMetersTimerCancellable != nil,
            isRecording,
            file: file,
            line: line
        )
    }

    private func setUpHasActiveCall(
        _ hasActiveCall: Bool,
        timeout: TimeInterval = 0.5
    ) async {
        _ = subject
        mockActiveCallProvider.hasActiveCall = hasActiveCall

        let waitExpectation = expectation(description: "Wait for an amount of time.")
        waitExpectation.isInverted = true
        await fulfillment(of: [waitExpectation], timeout: timeout)
    }
}

// Mocks for unit testing

private class MockAudioRecorder: AVAudioRecorder {
    private var _isRecoding = false
    override var isRecording: Bool { _isRecoding }

    override func record() -> Bool {
        _isRecoding = true
        return _isRecoding
    }

    override func stop() {
        _isRecoding = false
    }

    override func updateMeters() {
        // Simulate meter update
    }
}

private class MockAudioSession: AudioSessionProtocol {

    var category: AVAudioSession.Category = .playback
    var active = false
    var recordPermission = false

    func setCategory(_ category: AVAudioSession.Category) throws {
        self.category = category
    }

    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions = []) throws {
        self.active = active
    }

    func requestRecordPermission() async -> Bool {
        recordPermission
    }
}

private class MockStreamActiveCallProvider: StreamActiveCallProviding {
    private var _activeCallSubject = PassthroughSubject<Bool, Never>()

    var hasActiveCall: Bool! {
        didSet { _activeCallSubject.send(hasActiveCall!) }
    }

    var hasActiveCallPublisher: AnyPublisher<Bool, Never> {
        _activeCallSubject.eraseToAnyPublisher()
    }
}

extension XCTestCase {

    func XCTAsyncUnwrap<T>(
        _ expression: @autoclosure () async throws -> T?,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> T {
        let expressionResult = try await expression()
        return try XCTUnwrap(expressionResult, message(), file: file, line: line)
    }
}
