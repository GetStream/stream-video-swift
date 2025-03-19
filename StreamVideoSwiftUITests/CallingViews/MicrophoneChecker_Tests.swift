//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

final class MicrophoneChecker_Tests: XCTestCase, @unchecked Sendable {

    private lazy var mockStreamVideo: MockStreamVideo! = .init()
    private lazy var subject: MicrophoneChecker! = .init(valueLimit: 3)
    private lazy var mockAudioRecorder: MockStreamCallAudioRecorder! = MockStreamCallAudioRecorder(filename: "test.wav")

    override func setUp() {
        super.setUp()
        _ = mockStreamVideo
        InjectedValues[\.callAudioRecorder] = mockAudioRecorder
    }

    override func tearDown() async throws {
        await subject.stopListening()
        InjectedValues[\.callAudioRecorder] = StreamCallAudioRecorderKey.currentValue
        mockAudioRecorder = nil
        mockStreamVideo = nil
        subject = nil
        try await super.tearDown()
    }

    // MARK: - init

    func test_startListening_startListeningWasCalledOnAudioRecorder() async {
        await subject.startListening()

        XCTAssertTrue(mockAudioRecorder.startRecordingWasCalled)
    }

    func test_startListening_threadSafety() async {
        await withTaskGroup(of: Void.self) { [weak self] group in
            // Start listening task
            group.addTask { [weak self] in
                await self?.subject.startListening()
            }

            // Simulate audio updates task
            group.addTask { [weak self] in
                let stream = AsyncStream<Float> { continuation in
                    let task = Task {
                        let startTime = Date()
                        while !Task.isCancelled {
                            continuation.yield(Float.random(in: 0...100))
                            try? await Task.sleep(nanoseconds: 100_000_000)

                            // Check if 2 seconds have elapsed
                            if Date().timeIntervalSince(startTime) >= 2.0 {
                                break
                            }
                        }
                        continuation.finish()
                    }
                    
                    continuation.onTermination = { @Sendable _ in
                        task.cancel()
                    }
                }
                
                for await value in stream {
                    self?.mockAudioRecorder.mockMetersPublisher.send(value)
                }
            }

            // Cleanup task
            group.addTask { [weak self] in
                self?.subject = nil
            }
        }
    }

    // MARK: - stopListening

    func test_stopListening_stopListeningWasCalledOnAudioRecorder() async {
        await subject.stopListening()

        XCTAssertTrue(mockAudioRecorder.stopRecordingWasCalled)
    }

    // MARK: - audioLevels

    func test_startListeningAndPostAudioLevels_microphoneCheckerHasExpectedValues() async throws {
        LogConfig.level = .debug
        await subject.startListening()

        let inputs = [
            -100,
             -25,
             -10,
             -50
        ]

        for value in inputs {
            mockAudioRecorder.mockMetersPublisher.send(Float(value))
            try? await Task.sleep(nanoseconds: 100_000)
        }

        let values = try await subject
            .$audioLevels
            .filter { $0 == [0.5, 0.8, 0.0] }
            .nextValue(timeout: defaultTimeout)

        XCTAssertEqual(values, [0.5, 0.8, 0.0])
    }
}

private final class MockStreamCallAudioRecorder: StreamCallAudioRecorder, @unchecked Sendable {

    private(set) var startRecordingWasCalled = false
    private(set) var stopRecordingWasCalled = false

    private(set) var mockMetersPublisher: PassthroughSubject<Float, Never> = .init()
    override var metersPublisher: AnyPublisher<Float, Never> { mockMetersPublisher.eraseToAnyPublisher() }

    override func startRecording(ignoreActiveCall: Bool) async {
        startRecordingWasCalled = true
    }

    override func stopRecording() async {
        stopRecordingWasCalled = true
    }
}
