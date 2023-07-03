//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class MicrophoneManager_Tests: XCTestCase {

    func test_microphoneManager_toggle() async throws {
        // Given
        let microphoneManager = MicrophoneManager(
            callController: CallController_Mock.make(),
            settings: CallSettings()
        )
        
        // When
        try await microphoneManager.toggle()
        
        // Then
        XCTAssert(microphoneManager.status == .disabled)
        XCTAssert(microphoneManager.callSettings.audioOn == false)
    }
    
    func test_microphoneManager_enable() async throws {
        // Given
        let microphoneManager = MicrophoneManager(
            callController: CallController_Mock.make(),
            settings: CallSettings(audioOn: false)
        )
        
        // When
        try await microphoneManager.enable()
        
        // Then
        XCTAssert(microphoneManager.status == .enabled)
        XCTAssert(microphoneManager.callSettings.audioOn == true)
    }
    
    func test_microphoneManager_disable() async throws {
        // Given
        let microphoneManager = MicrophoneManager(
            callController: CallController_Mock.make(),
            settings: CallSettings()
        )
        
        // When
        try await microphoneManager.disable()
        
        // Then
        XCTAssert(microphoneManager.status == .disabled)
        XCTAssert(microphoneManager.callSettings.audioOn == false)
    }
    
    func test_microphoneManager_sameState() async throws {
        // Given
        let microphoneManager = MicrophoneManager(
            callController: CallController_Mock.make(),
            settings: CallSettings()
        )
        
        // When
        try await microphoneManager.enable()
        
        // Then
        XCTAssert(microphoneManager.status == .enabled)
        XCTAssert(microphoneManager.callSettings.audioOn == true)
    }
    
}
