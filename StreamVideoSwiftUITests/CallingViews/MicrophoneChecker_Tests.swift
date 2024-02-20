//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest
@testable import StreamVideoSwiftUI
import AVFoundation
import StreamVideo
import Combine

final class MicrophoneChecker_Tests: XCTestCase {

    private lazy var subject: MicrophoneChecker! = .init(valueLimit: 3)
    private lazy var mockAudioRecorder: MockStreamCallAudioRecorder! = MockStreamCallAudioRecorder(filename: "test.wav")

    override func setUp() {
        super.setUp()
        InjectedValues[\.callAudioRecorder] = mockAudioRecorder
    }

    override func tearDown() {
        mockAudioRecorder = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - init

    func test_startListening_startListeningWasCalledOnAudioRecorder() async {
        await subject.startListening()

        XCTAssertTrue(mockAudioRecorder.startRecordingWasCalled)
    }

    // MARK: - stopListening

    func test_stopListening_stopListeningWasCalledOnAudioRecorder() async {
        await subject.stopListening()

        XCTAssertTrue(mockAudioRecorder.stopRecordingWasCalled)
    }

    // MARK: - audioLevels

    func test_startListeningAndPostAudioLevels_microphoneCheckerHasExpectedValues() async {
        await subject.startListening()

        mockAudioRecorder.mockMetersPublisher.send(-100)
        mockAudioRecorder.mockMetersPublisher.send(-25)
        mockAudioRecorder.mockMetersPublisher.send(-10)
        mockAudioRecorder.mockMetersPublisher.send(-50)

        let waitExpectation = expectation(description: "Wait for time interval...")
        waitExpectation.isInverted = true
        await fulfillment(of: [waitExpectation], timeout: 1)

        XCTAssertEqual(subject.audioLevels, [0.5, 0.8, 0.0])
    }
}

private final class MockStreamCallAudioRecorder: StreamCallAudioRecorder {

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
