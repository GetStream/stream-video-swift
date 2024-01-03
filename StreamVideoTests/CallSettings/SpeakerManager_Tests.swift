//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class SpeakerManager_Tests: XCTestCase {

    func test_speaker_disable() async throws {
        // Given
        let speakerManager = SpeakerManager(
            callController: CallController_Mock.make(),
            initialSpeakerStatus: .enabled,
            initialAudioOutputStatus: .enabled
        )
        
        // When
        try await speakerManager.disableSpeakerPhone()
        
        // Then
        XCTAssert(speakerManager.status == .disabled)
    }
    
    func test_speaker_enable() async throws {
        // Given
        let speakerManager = SpeakerManager(
            callController: CallController_Mock.make(),
            initialSpeakerStatus: .disabled,
            initialAudioOutputStatus: .enabled
        )
        
        // When
        try await speakerManager.enableSpeakerPhone()
        
        // Then
        XCTAssert(speakerManager.status == .enabled)
    }
    
    func test_speaker_disableSound() async throws {
        // Given
        let speakerManager = SpeakerManager(
            callController: CallController_Mock.make(),
            initialSpeakerStatus: .enabled,
            initialAudioOutputStatus: .enabled
        )
        
        // When
        try await speakerManager.disableAudioOutput()
        
        // Then
        XCTAssert(speakerManager.audioOutputStatus == .disabled)
    }
    
    func test_speaker_enableSound() async throws {
        // Given
        let speakerManager = SpeakerManager(
            callController: CallController_Mock.make(),
            initialSpeakerStatus: .enabled,
            initialAudioOutputStatus: .disabled
        )
        
        // When
        try await speakerManager.enableAudioOutput()
        
        // Then
        XCTAssert(speakerManager.audioOutputStatus == .enabled)
    }


}
