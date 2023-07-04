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
            initialStatus: .enabled
        )
        
        // When
        try await microphoneManager.toggle()
        
        // Then
        XCTAssert(microphoneManager.status == .disabled)
    }
    
    func test_microphoneManager_enable() async throws {
        // Given
        let microphoneManager = MicrophoneManager(
            callController: CallController_Mock.make(),
            initialStatus: .disabled
        )
        
        // When
        try await microphoneManager.enable()
        
        // Then
        XCTAssert(microphoneManager.status == .enabled)
    }
    
    func test_microphoneManager_disable() async throws {
        // Given
        let microphoneManager = MicrophoneManager(
            callController: CallController_Mock.make(),
            initialStatus: .enabled
        )
        
        // When
        try await microphoneManager.disable()
        
        // Then
        XCTAssert(microphoneManager.status == .disabled)
    }
    
    func test_microphoneManager_sameState() async throws {
        // Given
        let microphoneManager = MicrophoneManager(
            callController: CallController_Mock.make(),
            initialStatus: .enabled
        )
        
        // When
        try await microphoneManager.enable()
        
        // Then
        XCTAssert(microphoneManager.status == .enabled)
    }
    
}
