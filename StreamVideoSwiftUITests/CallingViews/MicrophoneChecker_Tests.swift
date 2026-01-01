//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

final class MicrophoneChecker_Tests: XCTestCase, @unchecked Sendable {

    private var mockStreamVideo: MockStreamVideo! = .init()
    private lazy var mockAudioRecorder: MockStreamCallAudioRecorder! = .init()
    private lazy var subject: MicrophoneChecker! = .init(valueLimit: 3)

    override func setUp() {
        super.setUp()
        _ = mockAudioRecorder
        _ = subject
    }

    override func tearDown() async throws {
        await subject.stopListening()
        InjectedValues[\.callAudioRecorder] = StreamCallAudioRecorder()
        mockAudioRecorder = nil
        mockStreamVideo = nil
        subject = nil
        try await super.tearDown()
    }

    // MARK: - init

    func test_startListeningAndPostAudioLevels_microphoneCheckerHasExpectedValues() async throws {
        mockAudioRecorder.startRecording(ignoreActiveCall: true)

        let inputs = [
            -100,
            -25,
            -10,
            -50
        ]

        for value in inputs {
            mockAudioRecorder.mockStore.dispatch(.setMeter(.init(value)))
            await wait(for: 0.1)
        }

        let values = try await subject
            .$audioLevels
            .filter { $0 == [0.5, 0.8, 0.0] }
            .nextValue(timeout: defaultTimeout)

        XCTAssertEqual(values, [0.5, 0.8, 0.0])
    }
}
