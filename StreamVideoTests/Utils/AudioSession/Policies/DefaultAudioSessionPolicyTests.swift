//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import XCTest

final class DefaultAudioSessionPolicyTests: XCTestCase, @unchecked Sendable {

    private lazy var subject: DefaultAudioSessionPolicy! = .init()
    
    override func tearDown() {
        subject = nil
        super.tearDown()
    }
    
    // MARK: - VideoCall

    func testConfiguration_WhenVideoCallWithSpeaker_ReturnsCorrectConfiguration() {
        let callSettings = CallSettings(videoOn: true, speakerOn: true)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio, .sendVideo]

        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )

        XCTAssertEqual(configuration.category, .playAndRecord)
        XCTAssertEqual(configuration.mode, .videoChat)
        XCTAssertEqual(configuration.options, .playAndRecord)
        XCTAssertEqual(configuration.overrideOutputAudioPort, .speaker)
    }
    
    func testConfiguration_WhenVideoCallWithoutSpeaker_ReturnsCorrectConfiguration() {
        let callSettings = CallSettings(videoOn: true, speakerOn: false)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio, .sendVideo]

        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )

        XCTAssertEqual(configuration.category, .playAndRecord)
        XCTAssertEqual(configuration.mode, .videoChat)
        XCTAssertEqual(configuration.options, .playAndRecord)
        XCTAssertEqual(configuration.overrideOutputAudioPort, AVAudioSession.PortOverride.none)
    }
    
    // MARK: - AudioCall

    func testConfiguration_WhenAudioCallWithSpeaker_ReturnsCorrectConfiguration() {
        let callSettings = CallSettings(videoOn: false, speakerOn: true)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio]

        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )

        XCTAssertEqual(configuration.category, .playAndRecord)
        XCTAssertEqual(configuration.mode, .voiceChat)
        XCTAssertEqual(configuration.options, .playAndRecord)
        XCTAssertEqual(configuration.overrideOutputAudioPort, .speaker)
    }
    
    func testConfiguration_WhenAudioCallWithoutSpeaker_ReturnsCorrectConfiguration() {
        // Δεδομένα
        let callSettings = CallSettings(videoOn: false, speakerOn: false)
        let ownCapabilities: Set<OwnCapability> = [.sendAudio]

        let configuration = subject.configuration(
            for: callSettings,
            ownCapabilities: ownCapabilities
        )
        
        XCTAssertEqual(configuration.category, .playAndRecord)
        XCTAssertEqual(configuration.mode, .voiceChat)
        XCTAssertEqual(configuration.options, .playAndRecord)
        XCTAssertEqual(configuration.overrideOutputAudioPort, AVAudioSession.PortOverride.none)
    }
}
