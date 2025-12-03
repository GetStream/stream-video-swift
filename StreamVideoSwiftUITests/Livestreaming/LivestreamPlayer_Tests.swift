//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
@preconcurrency import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

final class LivestreamPlayer_Tests: StreamVideoTestCase, @unchecked Sendable {
    
    private let callId = "test"
    private let callType = "livestream"
    private var mockStreamVideo: MockStreamVideo! = .init()

    override func tearDown() async throws {
        mockStreamVideo = nil
        try await super.tearDown()
    }

    @MainActor
    func test_livestreamPlayer_snapshot() async throws {
        // Given
        let call = streamVideo.call(callType: callType, callId: callId)
        call.state.backstage = false
        let player = LivestreamPlayer(call: call, joinPolicy: .none)
            .frame(width: defaultScreenSize.width, height: defaultScreenSize.height)
        
        // Then
        AssertSnapshot(player, variants: [.defaultLight, .defaultDark])
    }
    
    @MainActor
    func test_livestreamPlayer_snapshotHideParticipantCount() async throws {
        // Given
        let call = streamVideo.call(callType: callType, callId: callId)
        call.state.backstage = false
        let player = LivestreamPlayer(call: call, showParticipantCount: false, joinPolicy: .none)
            .frame(width: defaultScreenSize.width, height: defaultScreenSize.height)
        
        // Then
        AssertSnapshot(player, variants: [.defaultLight, .defaultDark])
    }
    
    @MainActor
    func test_livestreamPlayer_backstageStartsAt() async throws {
        // Given
        let countdown: TimeInterval = 120
        let call = streamVideo.call(callType: callType, callId: callId)
        call.state.backstage = true
        call.state.startsAt = Date(timeIntervalSinceNow: countdown)
        let player = LivestreamPlayer(call: call, countdown: countdown, joinPolicy: .none)
            .frame(width: defaultScreenSize.width, height: defaultScreenSize.height)
        
        // Then
        AssertSnapshot(player, variants: [.defaultLight, .defaultDark])
    }
    
    @MainActor
    func test_livestreamPlayer_backstageStartsAtWithParticipants() async throws {
        // Given
        let countdown: TimeInterval = 120
        let call = streamVideo.call(callType: callType, callId: callId)
        call.state.backstage = true
        call.state.startsAt = Date(timeIntervalSinceNow: countdown)
        call.state.session = CallSessionResponse.dummy(participants: [.dummy(), .dummy()])
        let player = LivestreamPlayer(call: call, countdown: countdown, joinPolicy: .none)
            .frame(width: defaultScreenSize.width, height: defaultScreenSize.height)
        
        // Then
        AssertSnapshot(player, variants: [.defaultLight, .defaultDark])
    }
    
    @MainActor
    func test_livestreamPlayer_errorState() async throws {
        // Given
        let call = streamVideo.call(callType: callType, callId: callId)
        let player = LivestreamPlayer(call: call, livestreamState: .error, joinPolicy: .none)
            .frame(width: defaultScreenSize.width, height: defaultScreenSize.height)
        
        // Then
        AssertSnapshot(player, variants: [.defaultLight, .defaultDark])
    }
    
    @MainActor
    func test_livestreamPlayer_joiningState() async throws {
        // Given
        let call = streamVideo.call(callType: callType, callId: callId)
        let player = LivestreamPlayer(call: call, livestreamState: .joining, joinPolicy: .none)
            .frame(width: defaultScreenSize.width, height: defaultScreenSize.height)
        
        // Then
        AssertSnapshot(player, variants: [.defaultLight, .defaultDark])
    }
    
    @MainActor
    func test_livestreamPlayer_endedState() async throws {
        // Given
        let call = MockCall()
        let recording = CallRecording(
            endTime: .now,
            filename: "test",
            startTime: .distantFuture,
            url: "https://test.com"
        )
        call.state.endedAt = .now
        
        // When
        let player = LivestreamPlayer(call: call, joinPolicy: .none, recordings: [recording])
            .frame(width: defaultScreenSize.width, height: defaultScreenSize.height)
        
        // Then
        AssertSnapshot(player, variants: [.defaultLight, .defaultDark])
    }
}
