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
    private var previousAdapter: StreamPictureInPictureAdapter?

    override func tearDown() async throws {
        mockStreamVideo = nil
        if let previousAdapter {
            InjectedValues[\.pictureInPictureAdapter] = previousAdapter
        }
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

    // MARK: - Picture in Picture

    @MainActor
    func test_livestreamPlayer_appears_adapterWithoutCall_setsTheCall() async {
        let adapter = injectPictureInPictureAdapter()
        let call = MockCall()

        let window = host(LivestreamPlayer(call: call, joinPolicy: .none))
        defer { window.isHidden = true }

        await fulfilmentInMainActor { adapter.call?.cId == call.cId }
    }

    @MainActor
    func test_livestreamPlayer_appears_adapterHoldsAnotherCall_keepsTheOtherCall() async {
        let adapter = injectPictureInPictureAdapter()
        let other = MockCall()
        adapter.call = other
        let lifecycle = Lifecycle()

        let window = host(LivestreamPlayer(call: MockCall(), joinPolicy: .none), lifecycle)
        defer { window.isHidden = true }
        await fulfilmentInMainActor { lifecycle.appeared }

        XCTAssertEqual(adapter.call?.cId, other.cId)
    }

    @MainActor
    func test_livestreamPlayer_disappears_clearsTheCallItSet() async {
        let adapter = injectPictureInPictureAdapter()
        let call = MockCall()
        let window = host(LivestreamPlayer(call: call, joinPolicy: .none))
        defer { window.isHidden = true }
        await fulfilmentInMainActor { adapter.call?.cId == call.cId }

        window.rootViewController = nil

        await fulfilmentInMainActor { adapter.call == nil }
    }

    @MainActor
    func test_livestreamPlayer_disappears_adapterHoldsAnotherCall_keepsTheOtherCall() async {
        let adapter = injectPictureInPictureAdapter()
        let call = MockCall()
        let other = MockCall()
        let lifecycle = Lifecycle()
        let window = host(LivestreamPlayer(call: call, joinPolicy: .none), lifecycle)
        defer { window.isHidden = true }
        await fulfilmentInMainActor { adapter.call?.cId == call.cId }
        adapter.call = other

        window.rootViewController = nil
        await fulfilmentInMainActor { lifecycle.disappeared }

        XCTAssertEqual(adapter.call?.cId, other.cId)
    }

    @MainActor
    func test_livestreamPlayer_disappears_appSetTheCall_keepsTheCall() async {
        let adapter = injectPictureInPictureAdapter()
        let call = MockCall()
        adapter.call = call
        let lifecycle = Lifecycle()
        let window = host(LivestreamPlayer(call: call, joinPolicy: .none), lifecycle)
        defer { window.isHidden = true }
        await fulfilmentInMainActor { lifecycle.appeared }

        window.rootViewController = nil
        await fulfilmentInMainActor { lifecycle.disappeared }

        XCTAssertEqual(adapter.call?.cId, call.cId)
    }

    @MainActor
    func test_livestreamPlayer_pictureInPictureDisabled_appears_leavesTheAdapterAlone() async {
        let adapter = injectPictureInPictureAdapter()
        let lifecycle = Lifecycle()

        let window = host(
            LivestreamPlayer(
                call: MockCall(),
                joinPolicy: .none,
                isPictureInPictureEnabled: false
            ),
            lifecycle
        )
        defer { window.isHidden = true }
        await fulfilmentInMainActor { lifecycle.appeared }

        XCTAssertNil(adapter.call)
    }

    // MARK: - HLS playback

    @MainActor
    func test_livestreamPlayer_toggleAudioOutput_hls_usesTheSpeaker() async throws {
        let fixture = await makeHLSFixture(playbackType: .hls(hlsURL))

        await fixture.subject.toggleAudioOutput()

        await fulfillment { fixture.callController.timesCalled(.changeSoundState) == 1 }
    }

    @MainActor
    func test_livestreamPlayer_toggleAudioOutput_webRTC_usesTheSpeaker() async throws {
        let fixture = await makeHLSFixture(playbackType: .webRTC)

        await fixture.subject.toggleAudioOutput()

        await fulfillment { fixture.callController.timesCalled(.changeSoundState) == 1 }
    }

    @MainActor
    func test_livestreamPlayer_startHLSPlayback_mutedOnStart_turnsTheAudioOutputOff() async throws {
        let fixture = await makeHLSFixture(playbackType: .hls(hlsURL), muted: true)

        await fixture.subject.startHLSPlayback()

        await fulfillment { fixture.callController.timesCalled(.changeSoundState) == 1 }
    }

    @MainActor
    func test_livestreamPlayer_startHLSPlayback_notMutedOnStart_keepsTheAudioOutput() async throws {
        let fixture = await makeHLSFixture(playbackType: .hls(hlsURL))

        await fixture.subject.startHLSPlayback()

        XCTAssertEqual(fixture.callController.timesCalled(.changeSoundState), 0)
    }

    @MainActor
    func test_livestreamPlayer_applyStreamPaused_hls_pausesAndResumesThePlayer() async throws {
        let fixture = await makeHLSFixture(playbackType: .hls(hlsURL))
        await fixture.subject.startHLSPlayback()
        let playCount = fixture.player.playCount

        await fixture.subject.applyStreamPaused(true)
        XCTAssertEqual(fixture.player.pauseCount, 1)

        await fixture.subject.applyStreamPaused(false)
        XCTAssertEqual(fixture.player.playCount, playCount + 1)
    }

    @MainActor
    func test_livestreamPlayer_applyStreamPaused_webRTC_doesNotTouchThePlayer() async throws {
        let fixture = await makeHLSFixture(playbackType: .webRTC)
        await fixture.subject.startHLSPlayback()

        await fixture.subject.applyStreamPaused(true)

        XCTAssertEqual(fixture.player.pauseCount, 0)
        XCTAssertEqual(fixture.player.playCount, 0)
    }

    @MainActor
    func test_livestreamPlayer_startHLSPlayback_streamPaused_pausesThePlayerAgain() async throws {
        let fixture = await makeHLSFixture(playbackType: .hls(hlsURL), streamPaused: true)

        await fixture.subject.startHLSPlayback()

        XCTAssertEqual(fixture.player.pauseCount, 1)
    }

    @MainActor
    func test_livestreamPlayer_startHLSPlayback_streamNotPaused_doesNotPauseThePlayer() async throws {
        let fixture = await makeHLSFixture(playbackType: .hls(hlsURL))

        await fixture.subject.startHLSPlayback()

        XCTAssertEqual(fixture.player.pauseCount, 0)
    }

    @MainActor
    func test_livestreamPlayer_followRate_playerPausedAndResumedFromOutside_updatesStreamPaused() async throws {
        let fixture = await makeHLSFixture(playbackType: .hls(hlsURL))
        fixture.player.stubbedItem = AVPlayerItem(url: hlsURL)
        fixture.player.stubbedRate = 1
        let streamPaused = Atomic<Bool>(wrappedValue: true)
        let binding = Binding(
            get: { streamPaused.wrappedValue },
            set: { streamPaused.wrappedValue = $0 }
        )
        let observer = fixture.subject.followRate(of: fixture.player, into: binding)

        await fulfillment { !streamPaused.wrappedValue }
        fixture.player.rate = 0
        await fulfillment { streamPaused.wrappedValue }
        fixture.player.rate = 1
        await fulfillment { !streamPaused.wrappedValue }

        XCTAssertEqual(fixture.player.pauseCount, 0)
        observer.cancel()
    }

    @MainActor
    func test_livestreamPlayer_followRate_invalidatedPlayer_doesNotPauseTheButton() async throws {
        let fixture = await makeHLSFixture(playbackType: .hls(hlsURL))
        fixture.player.stubbedItem = AVPlayerItem(url: hlsURL)
        fixture.player.stubbedRate = 1
        let streamPaused = Atomic<Bool>(wrappedValue: false)
        let binding = Binding(
            get: { streamPaused.wrappedValue },
            set: { streamPaused.wrappedValue = $0 }
        )
        let observer = fixture.subject.followRate(of: fixture.player, into: binding)

        fixture.player.invalidate()
        fixture.player.rate = 0

        await wait(for: 0.3)
        XCTAssertFalse(streamPaused.wrappedValue)
        observer.cancel()
    }

    @MainActor
    func test_livestreamPlayer_playbackTypeBecomesWebRTC_stopsFollowingThePlayerRate() async throws {
        let made = MadePlayers()
        let callController = MockCallController(
            hlsStateAdapter: HLSStateAdapter { _ in
                let player = MockHLSPlayer()
                player.stubbedItem = AVPlayerItem(url: self.hlsURL)
                made.players.append(player)
                return player
            }
        )
        let call = MockCall(.dummy(callController: callController))
        call.state.playbackType = .hls(hlsURL)
        let window = host(LivestreamPlayer(call: call, joinPolicy: .none))
        defer { window.isHidden = true }
        await fulfilmentInMainActor { made.players.count == 1 }
        let player = try XCTUnwrap(made.players.first)
        await wait(for: 0.3)
        // The observer of the rate reads the item when the rate changes.
        let readsWhileFollowing = player.currentItemReadCount
        player.rate = player.rate == 0 ? 1 : 0
        await wait(for: 0.2)
        XCTAssertGreaterThan(player.currentItemReadCount, readsWhileFollowing)

        call.state.playbackType = .webRTC
        await wait(for: 0.2)
        let reads = player.currentItemReadCount
        player.rate = player.rate == 0 ? 1 : 0
        await wait(for: 0.3)

        XCTAssertEqual(player.currentItemReadCount, reads)
    }

    @MainActor
    func test_livestreamPlayer_startHLSPlayback_afterAURLSwap_doesNotPauseTheNewPlayer() async throws {
        let players = [MockHLSPlayer(), MockHLSPlayer()]
        let made = MadePlayers()
        let callController = MockCallController(
            hlsStateAdapter: HLSStateAdapter { _ in
                let player = players[made.players.count]
                made.players.append(player)
                return player
            }
        )
        let call = MockCall(.dummy(callController: callController))
        call.state.playbackType = .hls(hlsURL)
        let subject = LivestreamPlayer(call: call, joinPolicy: .none)
        await subject.startHLSPlayback()

        call.state.playbackType = .hls(URL(string: "https://example.com/other.m3u8")!)
        await fulfillment { players[0].pauseCount == 1 }
        await subject.startHLSPlayback()

        XCTAssertEqual(players[1].pauseCount, 0)
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

    /// Replaces the shared adapter with a fresh one. Teardown restores it.
    @MainActor
    private func injectPictureInPictureAdapter() -> StreamPictureInPictureAdapter {
        previousAdapter = previousAdapter ?? InjectedValues[\.pictureInPictureAdapter]
        let adapter = StreamPictureInPictureAdapter()
        InjectedValues[\.pictureInPictureAdapter] = adapter
        return adapter
    }

    /// Hosts the view. The outer modifiers mark that the lifecycle callbacks
    /// ran. SwiftUI calls the callbacks of the player first.
    @MainActor
    private func host(_ view: some View, _ lifecycle: Lifecycle = .init()) -> UIWindow {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(
            rootView: view
                .onAppear { lifecycle.appeared = true }
                .onDisappear { lifecycle.disappeared = true }
        )
        window.makeKeyAndVisible()
        return window
    }

    @MainActor
    private final class Lifecycle {
        var appeared = false
        var disappeared = false
    }

    private var hlsURL: URL { URL(string: "https://example.com/live.m3u8")! }

    /// Builds a player whose call reports `playbackType` and whose HLS player
    /// is a mock.
    @MainActor
    private func makeHLSFixture(
        playbackType: PlaybackType,
        muted: Bool = false,
        streamPaused: Bool = false
    ) async -> HLSFixture {
        let player = MockHLSPlayer()
        let callController = MockCallController(
            hlsStateAdapter: HLSStateAdapter { _ in player }
        )
        let call = MockCall(.dummy(callController: callController))
        call.state.playbackType = playbackType
        let subject = LivestreamPlayer(
            call: call,
            muted: muted,
            joinPolicy: .none,
            streamPaused: streamPaused
        )
        return .init(
            subject: subject,
            player: player,
            callController: callController
        )
    }
}
