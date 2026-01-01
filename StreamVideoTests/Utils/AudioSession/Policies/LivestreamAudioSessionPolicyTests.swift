//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import XCTest

final class LivestreamAudioSessionPolicyTests: XCTestCase, @unchecked Sendable {

    private var subject: LivestreamAudioSessionPolicy!

    override func setUp() {
        super.setUp()
        subject = LivestreamAudioSessionPolicy()
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func test_configuration_whenCanSendAudio_prefersPlayAndRecord() {
        let callSettings = CallSettings(
            audioOn: true,
            videoOn: true,
            speakerOn: true,
            audioOutputOn: true
        )
        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: [.sendAudio]
        )

        XCTAssertEqual(configuration.isActive, callSettings.audioOutputOn)
        XCTAssertEqual(configuration.category, .playAndRecord)
        XCTAssertEqual(configuration.mode, .default)
        XCTAssertEqual(configuration.options, [.allowBluetoothA2DP])
        XCTAssertEqual(configuration.overrideOutputAudioPort, .speaker)
    }

    func test_configuration_whenCannotSendAudio_fallsBackToPlayback() {
        let callSettings = CallSettings(
            audioOn: false,
            videoOn: false,
            speakerOn: false,
            audioOutputOn: false
        )
        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: []
        )

        XCTAssertEqual(configuration.isActive, callSettings.audioOutputOn)
        XCTAssertEqual(configuration.category, .playback)
        XCTAssertEqual(configuration.mode, .default)
        XCTAssertEqual(configuration.options, [.allowBluetoothA2DP])
        XCTAssertNil(configuration.overrideOutputAudioPort)
    }
}
