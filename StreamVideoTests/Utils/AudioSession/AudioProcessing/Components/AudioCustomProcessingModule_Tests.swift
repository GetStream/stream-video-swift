//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

final class AudioCustomProcessingModule_Tests: XCTestCase, @unchecked Sendable {

    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Subject

    private lazy var subject: AudioCustomProcessingModule! = .init()

    override func tearDown() {
        subject = nil
        cancellables.removeAll()
        super.tearDown()
    }

    func test_delegateCallbacks_emitInitializeAndReleaseEvents() {
        var received: [AudioCustomProcessingModule.Event] = []

        subject.publisher
            .sink { received.append($0) }
            .store(in: &cancellables)

        subject.audioProcessingInitialize(sampleRate: 44100, channels: 2)
        subject.audioProcessingRelease()

        XCTAssertEqual(received.count, 2)

        guard received.count == 2 else { return }
        if case let .audioProcessingInitialize(sampleRateHz, channels) = received[0] {
            XCTAssertEqual(sampleRateHz, 44100)
            XCTAssertEqual(channels, 2)
        } else {
            XCTFail("Expected initialize event")
        }

        if case .audioProcessingRelease = received[1] {
            // ok
        } else {
            XCTFail("Expected release event")
        }
    }
}
