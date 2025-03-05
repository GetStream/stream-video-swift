//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class AudioSession_Tests: XCTestCase, @unchecked Sendable {

//    private lazy var subject: StreamAudioSessionAdapter! = StreamAudioSessionAdapter()
//    private lazy var rtcAudioSession: RTCAudioSession! = .sharedInstance()
//
//    private var updatedCallSettings: CallSettings?
//    private var didReceiveUpdateCallSettings: Bool = false

    // MARK: - Lifecycle

//    override func setUp() {
//        super.setUp()
//        subject.delegate = self
//    }

//    override func tearDown() {
//        subject = nil
//        rtcAudioSession = nil
//        updatedCallSettings = nil
//        super.tearDown()
//    }

//    // MARK: - StreamAudioSessionAdapterDelegate
//
//    func audioSessionDidUpdateCallSettings(
//        _ audioSession: StreamAudioSessionAdapter,
//        callSettings: CallSettings
//    ) {
//        didReceiveUpdateCallSettings = true
//        updatedCallSettings = callSettings
//    }

    // MARK: - didUpdateCallSettings

//    func test_didUpdateCallSettings_updatesActiveCallSettings() {
//        // Given
//        let callSettings = CallSettings(speakerOn: true, audioOutputOn: true)
//
//        // When
//        subject.didUpdateCallSettings(callSettings)
//
//        // Then
//        XCTAssertEqual(subject.activeCallSettings, callSettings)
//    }

//    func test_didUpdateCallSettings_respectsCallSettingsIfAlreadyActive() {
//        // Given
//        let initialSettings = CallSettings(speakerOn: true, audioOutputOn: true)
//        subject.didUpdateCallSettings(initialSettings)
//        let newSettings = initialSettings // No change
//
//        // When
//        subject.didUpdateCallSettings(newSettings)
//
//        // Then
//        XCTAssertEqual(subject.activeCallSettings, initialSettings)
//        XCTAssertFalse(didReceiveUpdateCallSettings)
//    }

    // MARK: - audioSessionDidChangeRoute

//    func test_audioSessionDidChangeRoute_updatesRouteOnNewDeviceAvailable() {
//        // Given
//        let previousRoute = AVAudioSessionRouteDescription()
//        let callSettings = CallSettings(speakerOn: true, audioOutputOn: true)
//        subject.didUpdateCallSettings(callSettings)
//
//        // When
//        subject.audioSessionDidChangeRoute(
//            rtcAudioSession,
//            reason: .newDeviceAvailable,
//            previousRoute: previousRoute
//        )
//
//        // Then
//        XCTAssertNotNil(updatedCallSettings)
//    }

//    func test_audioSessionDidChangeRoute_respectsCallSettingsOnOldDeviceUnavailable() {
//        // Given
//        let previousRoute = AVAudioSessionRouteDescription()
//        let callSettings = CallSettings(audioOutputOn: true, speakerOn: true)
//        subject.didUpdateCallSettings(callSettings)
//
//        // When
//        subject.audioSessionDidChangeRoute(
//            mockAudioSession,
//            reason: .oldDeviceUnavailable,
//            previousRoute: previousRoute
//        )
//
//        // Then
//        XCTAssertEqual(mockDelegate.updatedCallSettings?.speakerOn, callSettings.speakerOn)
//    }

    // MARK: - audioSession(didChangeCanPlayOrRecord:)

//    func test_audioSession_didChangeCanPlayOrRecord_logsCorrectly() {
//        // When
//        subject.audioSession(
//            mockAudioSession,
//            didChangeCanPlayOrRecord: true
//        )
//
//        // Then
//        XCTAssertTrue(mockAudioSession.loggedInfo.contains("can playOrRecord:true"))
//    }

    // MARK: - audioSessionDidStopPlayOrRecord

//    func test_audioSessionDidStopPlayOrRecord_logsCorrectly() {
//        // When
//        subject.audioSessionDidStopPlayOrRecord(mockAudioSession)
//
//        // Then
//        XCTAssertTrue(mockAudioSession.loggedInfo.contains("cannot playOrRecord"))
//    }

    // MARK: - audioSession(didSetActive:)

//    func test_audioSession_didSetActive_appliesCorrectCallSettings() {
//        // Given
//        let callSettings = CallSettings(audioOutputOn: true, speakerOn: true)
//        subject.didUpdateCallSettings(callSettings)
//
//        // When
//        subject.audioSession(
//            mockAudioSession,
//            didSetActive: true
//        )
//
//        // Then
//        XCTAssertEqual(mockDelegate.updatedCallSettings?.speakerOn, callSettings.speakerOn)
//    }

    // MARK: - Private Helpers

//    func test_performAudioSessionOperation_executesOperationOnProcessingQueue() {
//        // Given
//        let expectation = self.expectation(description: "Operation executed")
//
//        // When
//        subject.performAudioSessionOperation {
//            _ in
//            expectation.fulfill()
//        }
//
//        // Then
//        waitForExpectations(timeout: 1.0)
//    }
}
