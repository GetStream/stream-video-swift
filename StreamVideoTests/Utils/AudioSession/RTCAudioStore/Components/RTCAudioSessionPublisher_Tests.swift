//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RTCAudioSessionPublisher_Tests: XCTestCase, @unchecked Sendable {

    private lazy var subject: RTCAudioSessionPublisher! = .init(.sharedInstance())

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - audioSessionDidBeginInterruption

    func test_audioSessionDidBeginInterruption_publishedCorrectEvent() async {
        await assertEvent(.didBeginInterruption) {
            subject.audioSessionDidBeginInterruption(.sharedInstance())
        }
    }

    // MARK: - audioSessionDidEndInterruption

    func test_audioSessionDidEndInterruption_shouldResumeFalse_publishedCorrectEvent() async {
        await assertEvent(.didEndInterruption(shouldResumeSession: false)) {
            subject.audioSessionDidEndInterruption(.sharedInstance(), shouldResumeSession: false)
        }
    }

    func test_audioSessionDidEndInterruption_shouldResumeTrue_publishedCorrectEvent() async {
        await assertEvent(.didEndInterruption(shouldResumeSession: true)) {
            subject.audioSessionDidEndInterruption(.sharedInstance(), shouldResumeSession: true)
        }
    }

    // MARK: - audioSessionDidChangeRoute

    func test_audioSessionDidChangeRoute_publishedCorrectEvent() async {
        let reason = AVAudioSession.RouteChangeReason.noSuitableRouteForCategory
        let previousRoute = AVAudioSessionRouteDescription()
        let currentRoute = RTCAudioSession.sharedInstance().currentRoute
        await assertEvent(
            .didChangeRoute(
                reason: reason,
                from: previousRoute,
                to: currentRoute
            )
        ) {
            subject.audioSessionDidChangeRoute(
                .sharedInstance(),
                reason: reason,
                previousRoute: previousRoute
            )
        }
    }

    // MARK: - Private Helpers

    private func assertEvent(
        _ expected: RTCAudioSessionPublisher.Event,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        operation: () -> Void
    ) async {
        let sinkExpectation = expectation(description: "Sink was called.")
        let disposableBag = DisposableBag()
        subject
            .publisher
            .filter { $0 == expected }
            .sink { _ in sinkExpectation.fulfill() }
            .store(in: disposableBag)

        operation()
        await safeFulfillment(of: [sinkExpectation], file: file, line: line)
        disposableBag.removeAll()
    }
}
