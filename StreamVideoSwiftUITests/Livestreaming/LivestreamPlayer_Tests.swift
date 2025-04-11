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
    
    private let helper = LivestreamPlayerHelper()
    
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
    func testFormatTimeInterval_withOnlySeconds() {
        let result = helper.formatTimeInterval(7)
        XCTAssertEqual(result, "0:07")
    }
    
    @MainActor
    func testFormatTimeInterval_withMinutesAndSeconds() {
        let result = helper.formatTimeInterval(125) // 2 min 5 sec
        XCTAssertEqual(result, "2:05")
    }
    
    @MainActor
    func testFormatTimeInterval_withHoursMinutesSeconds() {
        let result = helper.formatTimeInterval(3723) // 1 hr 2 min 3 sec
        XCTAssertEqual(result, "1:02:03")
    }
    
    @MainActor
    func testFormatTimeInterval_withZeroInterval() {
        let result = helper.formatTimeInterval(0)
        XCTAssertEqual(result, "0:00")
    }
    
    // MARK: - duration(from:) tests
    
    @MainActor
    func testDurationFromCallState_withPositiveDuration() {
        let state = CallState()
        state.duration = 3661 // 1 hr 1 sec
        let result = helper.duration(from: state)
        // Default DateComponentsFormatter format with positional style
        XCTAssertEqual(result, "1:01:01")
    }
    
    @MainActor
    func testDurationFromCallState_withZeroDuration() {
        let state = CallState()
        state.duration = 0
        let result = helper.duration(from: state)
        XCTAssertNil(result)
    }
    
    @MainActor
    func testDurationFromCallState_withNegativeDuration() {
        let state = CallState()
        state.duration = -5
        let result = helper.duration(from: state)
        XCTAssertNil(result)
    }
}
