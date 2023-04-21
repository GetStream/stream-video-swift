//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class CallSettings_Tests: XCTestCase {

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

}
