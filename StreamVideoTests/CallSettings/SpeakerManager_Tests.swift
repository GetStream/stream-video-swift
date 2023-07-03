//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class SpeakerManager_Tests: XCTestCase {

    func test_speaker_disable() async throws {
        // Given
        let speakerManager = SpeakerManager(
            callController: CallController_Mock.make(),
            settings: CallSettings()
        )
        
        // When
        try await speakerManager.disableSpeakerPhone()
        
        // Then
        XCTAssert(speakerManager.callSettings.speakerOn == false)
    }
    
    func test_speaker_enable() async throws {
        // Given
        let speakerManager = SpeakerManager(
            callController: CallController_Mock.make(),
            settings: CallSettings(speakerOn: false)
        )
        
        // When
        try await speakerManager.enableSpeakerPhone()
        
        // Then
        XCTAssert(speakerManager.callSettings.speakerOn == true)
    }
    
    func test_speaker_disableSound() async throws {
        // Given
        let speakerManager = SpeakerManager(
            callController: CallController_Mock.make(),
            settings: CallSettings()
        )
        
        // When
        try await speakerManager.disableAudioOutput()
        
        // Then
        XCTAssert(speakerManager.callSettings.audioOutputOn == false)
    }
    
    func test_speaker_enableSound() async throws {
        // Given
        let speakerManager = SpeakerManager(
            callController: CallController_Mock.make(),
            settings: CallSettings(audioOutputOn: false)
        )
        
        // When
        try await speakerManager.enableAudioOutput()
        
        // Then
        XCTAssert(speakerManager.callSettings.audioOutputOn == true)
    }


}
