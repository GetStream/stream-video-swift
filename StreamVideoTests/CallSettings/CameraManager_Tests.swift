//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class CameraManager_Tests: XCTestCase, @unchecked Sendable {

    func test_cameraManager_toggle() async throws {
        // Given
        let cameraManager = CameraManager(
            callController: CallController_Mock.make(),
            initialStatus: .enabled,
            initialDirection: .front
        )
        
        // When
        try await cameraManager.toggle()
        
        // Then
        XCTAssert(cameraManager.status == .disabled)
    }
    
    func test_cameraManager_disable() async throws {
        // Given
        let cameraManager = CameraManager(
            callController: CallController_Mock.make(),
            initialStatus: .enabled,
            initialDirection: .front
        )
        
        // When
        try await cameraManager.disable()
        
        // Then
        XCTAssert(cameraManager.status == .disabled)
    }
    
    func test_cameraManager_flipToBack() async throws {
        // Given
        let cameraManager = CameraManager(
            callController: CallController_Mock.make(),
            initialStatus: .enabled,
            initialDirection: .front
        )
        
        // When
        try await cameraManager.flip()
        
        // Then
        XCTAssert(cameraManager.direction == .back)
    }
    
    func test_cameraManager_flipToFront() async throws {
        // Given
        let cameraManager = CameraManager(
            callController: CallController_Mock.make(),
            initialStatus: .enabled,
            initialDirection: .back
        )
        
        // When
        try await cameraManager.flip()
        
        // Then
        XCTAssert(cameraManager.direction == .front)
    }
}
