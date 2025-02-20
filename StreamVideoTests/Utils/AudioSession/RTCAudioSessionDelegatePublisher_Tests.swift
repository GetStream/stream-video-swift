//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
@testable import StreamVideo
import StreamWebRTC
import XCTest

@MainActor
final class RTCAudioSessionDelegatePublisherTests: XCTestCase, @unchecked Sendable {
    private var session: RTCAudioSession! = .sharedInstance()
    private var disposableBag: DisposableBag! = .init()
    private var subject: RTCAudioSessionDelegatePublisher! = .init()

    override func tearDown() {
        Task { @MainActor in
            subject = nil
            disposableBag.removeAll()
        }
        super.tearDown()
    }

    // MARK: - audioSessionDidBeginInterruption

    func test_audioSessionDidBeginInterruption_givenSession_whenCalled_thenPublishesEvent() {
        assertAudioSessionEvent(
            subject.audioSessionDidBeginInterruption(session),
            validator: {
                if case let .didBeginInterruption(receivedSession) = $0 {
                    XCTAssertEqual(receivedSession, self.session)
                }
            }
        )
    }

    // MARK: - audioSessionDidEndInterruption

    func test_audioSessionDidEndInterruption_givenSessionAndShouldResume_whenCalled_thenPublishesEvent() {
        assertAudioSessionEvent(
            subject.audioSessionDidEndInterruption(session, shouldResumeSession: true),
            validator: {
                if case let .didEndInterruption(receivedSession, receivedShouldResume) = $0 {
                    XCTAssertEqual(receivedSession, self.session)
                    XCTAssertTrue(receivedShouldResume)
                }
            }
        )
    }

    // MARK: - audioSessionDidChangeRoute

    func test_audioSessionDidChangeRoute_givenSessionReasonAndPreviousRoute_whenCalled_thenPublishesEvent() {
        let reason: AVAudioSession.RouteChangeReason = .newDeviceAvailable
        let previousRoute = AVAudioSessionRouteDescription()

        assertAudioSessionEvent(
            subject.audioSessionDidChangeRoute(
                session,
                reason: reason,
                previousRoute: previousRoute
            ),
            validator: {
                if case let .didChangeRoute(receivedSession, receivedReason, receivedPreviousRoute) = $0 {
                    XCTAssertEqual(receivedSession, self.session)
                    XCTAssertEqual(receivedReason, reason)
                    XCTAssertEqual(receivedPreviousRoute, previousRoute)
                }
            }
        )
    }

    // MARK: - audioSessionMediaServerTerminated

    func test_audioSessionMediaServerTerminated_givenSession_whenCalled_thenPublishesEvent() {
        assertAudioSessionEvent(
            subject.audioSessionMediaServerTerminated(session),
            validator: {
                if case let .mediaServerTerminated(receivedSession) = $0 {
                    XCTAssertEqual(receivedSession, self.session)
                }
            }
        )
    }

    // MARK: - audioSessionMediaServerReset

    func test_audioSessionMediaServerReset_givenSession_whenCalled_thenPublishesEvent() {
        assertAudioSessionEvent(
            subject.audioSessionMediaServerReset(session),
            validator: {
                if case let .mediaServerReset(receivedSession) = $0 {
                    XCTAssertEqual(receivedSession, self.session)
                }
            }
        )
    }

    // MARK: - audioSessionDidChangeCanPlayOrRecord

    func test_audioSessionDidChangeCanPlayOrRecord_givenSessionAndCanPlayOrRecord_whenCalled_thenPublishesEvent() {
        assertAudioSessionEvent(
            subject.audioSession(session, didChangeCanPlayOrRecord: true),
            validator: {
                if case let .didChangeCanPlayOrRecord(receivedSession, receivedCanPlayOrRecord) = $0 {
                    XCTAssertEqual(receivedSession, self.session)
                    XCTAssertTrue(receivedCanPlayOrRecord)
                }
            }
        )
    }

    // MARK: - audioSessionDidStartPlayOrRecord

    func test_audioSessionDidStartPlayOrRecord_givenSession_whenCalled_thenPublishesEvent() {
        assertAudioSessionEvent(
            subject.audioSessionDidStartPlayOrRecord(session),
            validator: {
                if case let .didStartPlayOrRecord(receivedSession) = $0 {
                    XCTAssertEqual(receivedSession, self.session)
                }
            }
        )
    }

    // MARK: - audioSessionDidStopPlayOrRecord

    func test_audioSessionDidStopPlayOrRecord_givenSession_whenCalled_thenPublishesEvent() {
        assertAudioSessionEvent(
            subject.audioSessionDidStopPlayOrRecord(session),
            validator: {
                if case let .didStopPlayOrRecord(receivedSession) = $0 {
                    XCTAssertEqual(receivedSession, self.session)
                }
            }
        )
    }

    // MARK: - audioSessionDidChangeOutputVolume

    func test_audioSessionDidChangeOutputVolume_givenSessionAndOutputVolume_whenCalled_thenPublishesEvent() {
        assertAudioSessionEvent(
            subject.audioSession(session, didChangeOutputVolume: 0.5),
            validator: {
                if case let .didChangeOutputVolume(receivedSession, receivedOutputVolume) = $0 {
                    XCTAssertEqual(receivedSession, self.session)
                    XCTAssertEqual(receivedOutputVolume, 0.5)
                }
            }
        )
    }

    // MARK: - audioSessionDidDetectPlayoutGlitch

    func test_audioSessionDidDetectPlayoutGlitch_givenSessionAndTotalNumberOfGlitches_whenCalled_thenPublishesEvent() {
        assertAudioSessionEvent(
            subject.audioSession(session, didDetectPlayoutGlitch: 10),
            validator: {
                if case let .didDetectPlayoutGlitch(receivedSession, receivedTotalNumberOfGlitches) = $0 {
                    XCTAssertEqual(receivedSession, self.session)
                    XCTAssertEqual(receivedTotalNumberOfGlitches, 10)
                }
            }
        )
    }

    // MARK: - audioSessionWillSetActive

    func test_audioSessionWillSetActive_givenSessionAndActive_whenCalled_thenPublishesEvent() {
        assertAudioSessionEvent(
            subject.audioSession(session, willSetActive: true),
            validator: {
                if case let .willSetActive(receivedSession, receivedActive) = $0 {
                    XCTAssertEqual(receivedSession, self.session)
                    XCTAssertTrue(receivedActive)
                }
            }
        )
    }

    // MARK: - audioSessionDidSetActive

    func test_audioSessionDidSetActive_givenSessionAndActive_whenCalled_thenPublishesEvent() {
        assertAudioSessionEvent(
            subject.audioSession(session, didSetActive: true),
            validator: {
                if case let .didSetActive(receivedSession, receivedActive) = $0 {
                    XCTAssertEqual(receivedSession, self.session)
                    XCTAssertTrue(receivedActive)
                }
            }
        )
    }

    // MARK: - audioSessionFailedToSetActive

    func test_audioSessionFailedToSetActive_givenSessionActiveAndError_whenCalled_thenPublishesEvent() {
        let error = NSError(domain: "TestError", code: 1, userInfo: nil)
        assertAudioSessionEvent(
            subject.audioSession(session, failedToSetActive: true, error: error),
            validator: {
                if case let .failedToSetActive(receivedSession, receivedActive, receivedError) = $0 {
                    XCTAssertEqual(receivedSession, self.session)
                    XCTAssertTrue(receivedActive)
                    XCTAssertEqual(receivedError as NSError, error)
                }
            }
        )
    }

    // MARK: - audioSessionAudioUnitStartFailedWithError

    func test_audioSessionAudioUnitStartFailedWithError_givenSessionAndError_whenCalled_thenPublishesEvent() {
        let error = NSError(domain: "TestError", code: 1, userInfo: nil)
        assertAudioSessionEvent(
            subject.audioSession(session, audioUnitStartFailedWithError: error),
            validator: {
                if case let .audioUnitStartFailedWithError(receivedSession, receivedError) = $0 {
                    XCTAssertEqual(receivedSession, self.session)
                    XCTAssertEqual(receivedError as NSError, error)
                }
            }
        )
    }

    // MARK: - Private helpers

    @MainActor
    private func assertAudioSessionEvent(
        _ action: @autoclosure () -> Void,
        validator: @escaping (AudioSessionEvent) -> Void
    ) {
        let expectation = self.expectation(description: "AudioSession event received.")
        _ = RTCAudioSession.sharedInstance()

        subject
            .publisher
            .sink {
                validator($0)
                expectation.fulfill()
            }
            .store(in: disposableBag)

        action()

        waitForExpectations(timeout: 1, handler: nil)
    }
}
