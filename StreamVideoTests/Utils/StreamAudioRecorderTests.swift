//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import XCTest

final class StreamAudioRecorderTests: XCTestCase {

    private lazy var builder: AVAudioRecorderBuilder! = .init(cachedResult: mockAudioRecorder)
    private lazy var mockAudioSession: MockAudioSession! = .init()
    private var mockAudioRecorder: MockAudioRecorder!
    private lazy var subject: StreamAudioRecorder! = .init(
        audioRecorderBuilder: builder,
        audioSession: mockAudioSession
    )

    override func setUp() async throws {
        try await super.setUp()
        mockAudioRecorder = try .init(
            url: URL(string: "test.wav")!,
            settings: AVAudioRecorderBuilder.defaultRecordingSettings
        )
    }

    override func tearDown() {
        builder = nil
        mockAudioSession = nil
        mockAudioRecorder = nil
        subject = nil
        super.tearDown()
    }

    // MARK: Initialization

    func testInitWithFilename_givenValidFilename_whenInitialized_thenSetsUpCorrectly() async throws {
        let filename = "test_recording.m4a"
        let recorder = StreamAudioRecorder(filename: filename)

        let actualFileURL = await recorder.audioRecorderBuilder.fileURL.lastPathComponent
        XCTAssertTrue(actualFileURL == filename)
        XCTAssertTrue(recorder.audioSession === AVAudioSession.sharedInstance())
    }

    func testInitWithBuilderAndSession_givenCustomBuilderAndSession_whenInitialized_thenUsesProvidedObjects() {
        XCTAssertTrue(subject.audioRecorderBuilder === builder)
        XCTAssertTrue(subject.audioSession === mockAudioSession)
    }

    // MARK: Deinitialization

    func testFileDeletion_givenRecordingExists_whenDeinitialized_thenDeletesFile() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory

        let filename = tempDirectory.appendingPathComponent("test_recording.m4a")
        let mockBuilder = AVAudioRecorderBuilder(cachedResult: try .init(url: filename, settings: [:]))
        var recorder: StreamAudioRecorder! = StreamAudioRecorder(
            audioRecorderBuilder: mockBuilder,
            audioSession: MockAudioSession()
        )

        await recorder.startRecording() // Simulate recording
        recorder = nil

        XCTAssertFalse(FileManager.default.fileExists(atPath: filename.standardizedFileURL.absoluteString))
    }

    // MARK: Public API

    func testStartRecording_givenPermissionNotGranted_whenStarted_thenRecordsAndMetersAreNotUpdated() async throws {
        mockAudioSession.recordPermission = false
        subject.hasActiveCall = true

        await subject.startRecording()

        let audioRecorder = try await XCTAsyncUnwrap(await builder.result)
        XCTAssertFalse(audioRecorder.isRecording)
        XCTAssertFalse(audioRecorder.isMeteringEnabled)
        XCTAssertNil(subject.updateMetersTimerCancellable)
    }

    func testStartRecording_givenPermissionGranted_whenStarted_thenRecordsAndMetersUpdates() async throws {
        mockAudioSession.recordPermission = true
        subject.hasActiveCall = true

        await subject.startRecording()

        let audioRecorder = try await XCTAsyncUnwrap(await builder.result)
        XCTAssertTrue(audioRecorder.isRecording)
        XCTAssertTrue(audioRecorder.isMeteringEnabled)
        XCTAssertNotNil(subject.updateMetersTimerCancellable)
    }

    func testStopRecording_givenRecording_whenStopped_thenStopsRecording() async throws {
        mockAudioSession.recordPermission = true
        subject.hasActiveCall = true

        await subject.startRecording()
        await subject.stopRecording()

        let audioRecorder = try await XCTAsyncUnwrap(await builder.result)
        XCTAssertFalse(audioRecorder.isRecording)
        XCTAssertTrue(mockAudioSession.active)
        XCTAssertNil(subject.updateMetersTimerCancellable)
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
