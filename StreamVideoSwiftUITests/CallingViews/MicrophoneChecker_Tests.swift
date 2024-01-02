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
    
    private lazy var notificationCenter: NotificationCenter! = .default
    private lazy var audioSession: MockAVAudioSession! = .init()
    private lazy var subject: MicrophoneChecker! = .init(
        valueLimit: 3,
        audioSession: audioSession,
        notificationCenter: notificationCenter
    )

    private var cancellable: AnyCancellable?

    override func tearDown() {
        cancellable = nil
        subject = nil
        audioSession = nil
        notificationCenter = nil
        super.tearDown()
    }

    // MARK: - init

    func test_startListening_audioSessionIsActiveWasCalled() {
        _ = subject
        
        XCTAssertTrue(audioSession.setActiveWasCalledWithIsActive ?? false)
    }

    // MARK: - stopListening

    func test_stopListening_audioSessionIsActiveWasNotCalled() {
        subject.startListening()

        subject.stopListening()

        XCTAssertTrue(audioSession.setActiveWasCalledWithIsActive ?? false)
    }

    // MARK: - CallNotification.callEnded notification

    func test_didReceiveCallEndedNotification_audioSessionIsActiveWasCalled() {
        subject.startListening()
        let waitExpectation = expectation(description: "Ensure CallNotification.callEnded was posted")
        cancellable = notificationCenter
            .publisher(for: NSNotification.Name(CallNotification.callEnded))
            .sink { _ in waitExpectation.fulfill() }

        notificationCenter.post(
            name: NSNotification.Name(CallNotification.callEnded),
            object: nil
        )

        wait(for: [waitExpectation], timeout: defaultTimeout)
        XCTAssertFalse(audioSession.setActiveWasCalledWithIsActive ?? true)
    }
}

private final class MockAVAudioSession: AudioSessionProtocol {

    private(set) var setActiveWasCalledWithIsActive: Bool?

    func setCategory(_ category: AVAudioSession.Category) throws { /* No-op */ }

    func setActive(
        _ active: Bool,
        options: AVAudioSession.SetActiveOptions
    ) throws {
        setActiveWasCalledWithIsActive = active
    }

    func requestRecordPermission(_ response: @escaping (Bool) -> Void) { /* No-op */ }
}
