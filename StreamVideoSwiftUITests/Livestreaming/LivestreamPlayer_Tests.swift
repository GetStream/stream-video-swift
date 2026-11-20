//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import SnapshotTesting
@preconcurrency import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import SwiftUI
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
    func test_livestreamPlayer_disappears_reportsAppInitiator() async {
        let call = MockCall()
        call.stub(for: .join, with: JoinCallResponse.dummy())
        let subject = UIHostingController(rootView: LivestreamPlayer(call: call))
        let window = UIWindow(frame: UIScreen.main.bounds)
        let container = UIViewController()
        container.addChild(subject)
        // Match snapshot traits before the spinner is first rendered.
        container.setOverrideTraitCollection(
            SnapshotVariant.defaultLight.traits,
            forChild: subject
        )
        subject.view.frame = window.bounds
        container.view.addSubview(subject.view)
        subject.didMove(toParent: container)
        window.rootViewController = container
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        await fulfillment { call.timesCalled(.join) == 1 }

        window.rootViewController = nil

        await fulfillment { call.timesCalled(.leave) == 1 }
        XCTAssertEqual(call.leaveInitiators, [.app])
    }

    @MainActor
    func test_livestreamPlayer_leave_reportsUserInitiator() {
        let call = MockCall()
        let subject = LivestreamPlayer(call: call)

        subject.leaveLivestream()

        XCTAssertEqual(call.leaveInitiators, [.user])
    }

    // MARK: - HLS playback

    @MainActor
    func test_livestreamPlayer_toggleAudioOutput_hls_mutesThePlayerNotTheSpeaker() async throws {
        let fixture = makeHLSFixture(playbackType: .hls(hlsURL))
        fixture.subject.startHLSPlayback()

        fixture.subject.toggleAudioOutput()

        XCTAssertTrue(fixture.player.isMuted)
        XCTAssertEqual(fixture.callController.timesCalled(.changeSoundState), 0)
    }

    @MainActor
    func test_livestreamPlayer_toggleAudioOutput_webRTC_mutesTheSpeakerNotThePlayer() async throws {
        let fixture = makeHLSFixture(playbackType: .webRTC)
        fixture.subject.startHLSPlayback()

        fixture.subject.toggleAudioOutput()

        await fulfillment { fixture.callController.timesCalled(.changeSoundState) == 1 }
        XCTAssertFalse(fixture.player.isMuted)
    }

    @MainActor
    func test_livestreamPlayer_startHLSPlayback_mutedOnStart_mutesThePlayer() async throws {
        let fixture = makeHLSFixture(playbackType: .hls(hlsURL), muted: true)

        fixture.subject.startHLSPlayback()

        XCTAssertTrue(fixture.player.isMuted)
    }

    @MainActor
    func test_livestreamPlayer_applyStreamPaused_hls_pausesAndResumesThePlayer() async throws {
        let fixture = makeHLSFixture(playbackType: .hls(hlsURL))
        fixture.subject.startHLSPlayback()
        let playCount = fixture.player.playCount

        fixture.subject.applyStreamPaused(true)
        XCTAssertEqual(fixture.player.pauseCount, 1)

        fixture.subject.applyStreamPaused(false)
        XCTAssertEqual(fixture.player.playCount, playCount + 1)
    }

    @MainActor
    func test_livestreamPlayer_applyStreamPaused_webRTC_doesNotTouchThePlayer() async throws {
        let fixture = makeHLSFixture(playbackType: .webRTC)
        fixture.subject.startHLSPlayback()

        fixture.subject.applyStreamPaused(true)

        XCTAssertEqual(fixture.player.pauseCount, 0)
        XCTAssertEqual(fixture.player.playCount, 0)
    }

    @MainActor
    func test_livestreamPlayer_startHLSPlayback_streamPaused_pausesThePlayerAgain() async throws {
        let fixture = makeHLSFixture(playbackType: .hls(hlsURL), streamPaused: true)

        fixture.subject.startHLSPlayback()

        XCTAssertEqual(fixture.player.pauseCount, 1)
    }

    @MainActor
    func test_livestreamPlayer_startHLSPlayback_streamNotPaused_doesNotPauseThePlayer() async throws {
        let fixture = makeHLSFixture(playbackType: .hls(hlsURL))

        fixture.subject.startHLSPlayback()

        XCTAssertEqual(fixture.player.pauseCount, 0)
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
            recordingType: "composite",
            sessionId: "test",
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

    // MARK: - Private Helpers

    private struct HLSFixture {
        let subject: LivestreamPlayer<DefaultViewFactory>
        let player: HLSSpyPlayer
        let store: HLSPlayerStore
        let callController: MockCallController
        /// The claim the renderer holds on the player.
        let lease: (any HLSPlayerLeasing)?
    }

    private var hlsURL: URL { URL(string: "https://example.com/live.m3u8")! }

    /// Builds a player whose call reports `playbackType` and whose HLS player
    /// is a spy.
    @MainActor
    private func makeHLSFixture(
        playbackType: PlaybackType,
        muted: Bool = false,
        streamPaused: Bool = false
    ) -> HLSFixture {
        let player = HLSSpyPlayer()
        let store = HLSPlayerStore { _ in player }
        let callController = MockCallController()
        let call = MockCall(.dummy(callController: callController))
        call.state.playbackType = playbackType
        let lease = store.acquire(for: call, playbackType: playbackType)
        let subject = LivestreamPlayer(
            call: call,
            muted: muted,
            joinPolicy: .none,
            streamPaused: streamPaused,
            hlsPlayerStore: store
        )
        return .init(
            subject: subject,
            player: player,
            store: store,
            callController: callController,
            lease: lease
        )
    }
}
