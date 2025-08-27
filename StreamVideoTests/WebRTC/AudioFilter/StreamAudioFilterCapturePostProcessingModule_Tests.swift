//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class StreamAudioFilterCapturePostProcessingModule_Tests: XCTestCase, @unchecked Sendable {

    private lazy var audioFilter: MockAudioFilter! = .init()
    private lazy var subject: StreamAudioFilterCapturePostProcessingModule! = .init()

    override func tearDown() {
        subject = nil
        audioFilter = nil
        super.tearDown()
    }

    // MARK: - applyEffect

    func test_applyEffect_HiFiIsDisabled_audioFilterWasCalled() {
        subject.audioProcessingInitialize(sampleRate: 10, channels: 1)
        subject.setAudioFilter(audioFilter)
        subject.isHiFiEnabled = false

        subject.audioProcessingProcess(audioBuffer: .init())

        XCTAssertEqual(audioFilter.timesCalled(.applyEffect), 1)
    }

    func test_applyEffect_HiFiIsEnabled_audioFilterWasNotCalled() {
        subject.audioProcessingInitialize(sampleRate: 10, channels: 1)
        subject.setAudioFilter(audioFilter)
        subject.isHiFiEnabled = true

        subject.audioProcessingProcess(audioBuffer: .init())

        XCTAssertEqual(audioFilter.timesCalled(.applyEffect), 0)
    }
}
