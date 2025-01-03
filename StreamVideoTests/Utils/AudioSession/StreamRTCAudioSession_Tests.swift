//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class StreamRTCAudioSession_Tests: XCTestCase {

    // MARK: - Lazy Properties

    private var rtcAudioSession: RTCAudioSession! = .sharedInstance()
    private lazy var subject: StreamRTCAudioSession! = StreamRTCAudioSession()

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        rtcAudioSession = nil
        super.tearDown()
    }

    // MARK: - isActive

    func test_isActive_returnsCorrectState() throws {
        // Given
        XCTAssertEqual(subject.isActive, rtcAudioSession.isActive)

        // When
        rtcAudioSession.lockForConfiguration()
        try rtcAudioSession.setActive(true)
        rtcAudioSession.unlockForConfiguration()

        // Then
        XCTAssertTrue(rtcAudioSession.isActive)
        XCTAssertEqual(subject.isActive, rtcAudioSession.isActive)
    }

    // MARK: - currentRoute

    func test_currentRoute_returnsCorrectRoute() {
        XCTAssertEqual(subject.currentRoute.inputs.map(\.portType), rtcAudioSession.currentRoute.inputs.map(\.portType))
        XCTAssertEqual(subject.currentRoute.outputs.map(\.portType), rtcAudioSession.currentRoute.outputs.map(\.portType))
    }

    // MARK: - category

    func test_category_returnsCorrectCategory() throws {
        rtcAudioSession.lockForConfiguration()
        try rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord)
        rtcAudioSession.unlockForConfiguration()

        // Then
        XCTAssertEqual(subject.category, rtcAudioSession.category)
    }

    // MARK: - isUsingSpeakerOutput

    func test_isUsingSpeakerOutput_returnsCorrectValue() throws {
        // Given
        rtcAudioSession.lockForConfiguration()
        try rtcAudioSession.overrideOutputAudioPort(.speaker)
        rtcAudioSession.unlockForConfiguration()

        // When
        let isUsingSpeakerOutput = subject.isUsingSpeakerOutput

        // Then
        XCTAssertTrue(isUsingSpeakerOutput)
    }

    // MARK: - useManualAudio

    func test_useManualAudio_setAndGet() {
        // When
        subject.useManualAudio = true

        // Then
        XCTAssertTrue(rtcAudioSession.useManualAudio)
        XCTAssertEqual(subject.useManualAudio, rtcAudioSession.useManualAudio)
    }

    // MARK: - isAudioEnabled

    func test_isAudioEnabled_setAndGet() {
        // When
        subject.isAudioEnabled = true

        // Then
        XCTAssertTrue(rtcAudioSession.isAudioEnabled)
        XCTAssertEqual(subject.isAudioEnabled, rtcAudioSession.isAudioEnabled)
    }

    // MARK: - addDelegate

    func test_addDelegate() throws {
        final class MockRTCAudioSessionDelegate: NSObject, RTCAudioSessionDelegate {
            private(set) var didSetActiveWasCalled: Bool = false
            func audioSession(_ audioSession: RTCAudioSession, didSetActive active: Bool) { didSetActiveWasCalled = true }
        }

        // Given
        let delegate = MockRTCAudioSessionDelegate()
        subject.add(delegate)

        // When
        rtcAudioSession.lockForConfiguration()
        try rtcAudioSession.setActive(true)
        rtcAudioSession.unlockForConfiguration()

        // Then
        XCTAssertTrue(delegate.didSetActiveWasCalled)
    }

    // MARK: - setMode

    func test_setMode_modeUpdatedOnAudioSession() throws {
        // Given
        rtcAudioSession.lockForConfiguration()
        try subject.setMode(AVAudioSession.Mode.videoChat.rawValue)
        rtcAudioSession.unlockForConfiguration()

        // Then
        XCTAssertEqual(rtcAudioSession.mode, AVAudioSession.Mode.videoChat.rawValue)
    }

    // MARK: - setCategory

    func test_setCategory_categoryUpdatedOnAudioSession() throws {
        // Given
        rtcAudioSession.lockForConfiguration()
        try subject.setCategory(
            AVAudioSession.Category.playAndRecord.rawValue,
            with: [.allowBluetooth]
        )
        rtcAudioSession.unlockForConfiguration()

        // Then
        XCTAssertEqual(
            rtcAudioSession.category,
            AVAudioSession.Category.playAndRecord.rawValue
        )
        XCTAssertEqual(
            rtcAudioSession.categoryOptions,
            [.allowBluetooth]
        )
    }

    // MARK: - setActive

    func test_setActive_isActiveUpdatedOnAudioSession() throws {
        // Given
        rtcAudioSession.lockForConfiguration()
        try subject.setActive(true)
        rtcAudioSession.unlockForConfiguration()

        // Then
        XCTAssertTrue(rtcAudioSession.isActive)
    }

    // MARK: - setConfiguration

    func test_setConfiguration_configurationUpdatedOnAudioSession() throws {
        // Given
        rtcAudioSession.lockForConfiguration()
        let configuration = RTCAudioSessionConfiguration()
        configuration.category = AVAudioSession.Category.playAndRecord.rawValue
        configuration.categoryOptions = [.allowBluetooth]
        configuration.mode = AVAudioSession.Mode.videoChat.rawValue
        try subject.setConfiguration(configuration)
        rtcAudioSession.unlockForConfiguration()

        // Then
        XCTAssertEqual(rtcAudioSession.mode, AVAudioSession.Mode.videoChat.rawValue)
        XCTAssertEqual(
            rtcAudioSession.category,
            AVAudioSession.Category.playAndRecord.rawValue
        )
        XCTAssertEqual(
            rtcAudioSession.categoryOptions,
            [.allowBluetooth]
        )
    }

    // MARK: - updateConfiguration

    func test_updateConfiguration_executesBlockOnQueue() {
        // Given
        let expectation = self.expectation(description: "Configuration updated")

        // When
        subject.updateConfiguration(
            functionName: #function,
            file: #file,
            line: #line
        ) { session in
            try session.setMode(AVAudioSession.Mode.videoChat.rawValue)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: defaultTimeout)

        XCTAssertEqual(rtcAudioSession.mode, AVAudioSession.Mode.videoChat.rawValue)
    }
}
