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
        try await speakerManager.disable()
        
        // Then
        XCTAssert(speakerManager.callSettings.audioOutputOn == false)
    }
    
    func test_speaker_enable() async throws {
        // Given
        let speakerManager = SpeakerManager(
            callController: CallController_Mock.make(),
            settings: CallSettings(audioOutputOn: false)
        )
        
        // When
        try await speakerManager.enable()
        
        // Then
        XCTAssert(speakerManager.callSettings.audioOutputOn == true)
    }

}
