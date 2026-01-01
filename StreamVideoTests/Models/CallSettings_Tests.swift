//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class CallSettings_Tests: XCTestCase, @unchecked Sendable {

    func test_callSettings_shouldPublish() {
        // Given
        let callSettings = CallSettings()
        
        // When
        let shouldPublish = callSettings.shouldPublish
        
        // Then
        XCTAssert(shouldPublish == true)
    }
    
    func test_callSettings_shouldNotPublish() {
        // Given
        let callSettings = CallSettings(audioOn: false, videoOn: false)
        
        // When
        let shouldPublish = callSettings.shouldPublish
        
        // Then
        XCTAssert(shouldPublish == false)
    }
    
    func test_callSettings_updatedCameraPosition() {
        // Given
        var callSettings = CallSettings(cameraPosition: .front)
        
        // When
        callSettings = callSettings.withUpdatedCameraPosition(.back)
        
        // Then
        XCTAssert(callSettings.cameraPosition == .back)
    }
    
    func test_callSettings_updatedAudioState() {
        // Given
        var callSettings = CallSettings(audioOn: false)
        
        // When
        callSettings = callSettings.withUpdatedAudioState(true)
        
        // Then
        XCTAssert(callSettings.audioOn == true)
    }
    
    func test_callSettings_updatedVideoState() {
        // Given
        var callSettings = CallSettings(videoOn: true)
        
        // When
        callSettings = callSettings.withUpdatedVideoState(false)
        
        // Then
        XCTAssert(callSettings.videoOn == false)
    }

    func test_callSettings_updatedSpeakerState() {
        // Given
        var callSettings = CallSettings(speakerOn: true)
        
        // When
        callSettings = callSettings.withUpdatedSpeakerState(false)
        
        // Then
        XCTAssert(callSettings.speakerOn == false)
    }
    
    func test_callSettings_updatedAudioOutputState() {
        // Given
        var callSettings = CallSettings(audioOutputOn: true)
        
        // When
        callSettings = callSettings.withUpdatedAudioOutputState(false)
        
        // Then
        XCTAssert(callSettings.audioOutputOn == false)
    }
}
