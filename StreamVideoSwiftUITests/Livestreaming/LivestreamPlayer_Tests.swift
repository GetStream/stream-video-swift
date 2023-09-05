//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@testable import StreamVideoSwiftUI
import SnapshotTesting
import XCTest

final class LivestreamPlayer_Tests: StreamVideoTestCase {

    @MainActor
    func test_livestreamPlayer_snapshot() async throws {
        // Given
        let call = streamVideo?.call(callType: .livestream, callId: "test")
        
        // When
        let player = LivestreamPlayer(call: call!)
            .frame(width: defaultScreenSize.width, height: defaultScreenSize.height)
        
        // Then
        assertSnapshot(matching: player, as: .image)
    }
    
    @MainActor
    func test_livestreamPlayerVM_durationSeconds() {
        // Given
        let viewModel = LivestreamPlayerViewModel()
        let callState = CallState()
        callState.duration = 5
        
        // When
        let duration = viewModel.duration(from: callState)
        
        // Then
        XCTAssertEqual(duration, "5")
    }
    
    @MainActor
    func test_livestreamPlayerVM_durationMinutes() {
        // Given
        let viewModel = LivestreamPlayerViewModel()
        let callState = CallState()
        callState.duration = 65
        
        // When
        let duration = viewModel.duration(from: callState)
        
        // Then
        XCTAssertEqual(duration, "1:05")
    }

    @MainActor
    func test_livestreamPlayerVM_durationHours() {
        // Given
        let viewModel = LivestreamPlayerViewModel()
        let callState = CallState()
        callState.duration = 3605
        
        // When
        let duration = viewModel.duration(from: callState)
        
        // Then
        XCTAssertEqual(duration, "1:00:05")
    }
    
    @MainActor
    func test_livestreamPlayerVM_durationEmpty() {
        // Given
        let viewModel = LivestreamPlayerViewModel()
        let callState = CallState()
        
        // When
        let duration = viewModel.duration(from: callState)
        
        // Then
        XCTAssertNil(duration)
    }
    
    @MainActor
    func test_livestreamPlayerVM_updateFullScreen() {
        // Given
        let viewModel = LivestreamPlayerViewModel()
        
        // When
        viewModel.update(fullScreen: true)
        
        // Then
        XCTAssertEqual(viewModel.fullScreen, true)
    }
    
    @MainActor
    func test_livestreamPlayerVM_updateControlsShown() {
        // Given
        let viewModel = LivestreamPlayerViewModel()
        
        // When
        viewModel.update(controlsShown: false)
        
        // Then
        XCTAssertEqual(viewModel.controlsShown, false)
    }
    
    @MainActor
    func test_livestreamPlayerVM_pauseStream() {
        // Given
        let viewModel = LivestreamPlayerViewModel()
        
        // When
        viewModel.update(streamPaused: true)
        
        // Then
        XCTAssertEqual(viewModel.streamPaused, true)
    }
}
