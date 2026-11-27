//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamVideo
import XCTest

@MainActor
final class HLSStateAdapter_Tests: StreamVideoTestCase, @unchecked Sendable {

    private let url = URL(string: "https://example.com/live.m3u8")!
    private let otherURL = URL(string: "https://example.com/other.m3u8")!
    private let made = MadePlayers()
    private lazy var call: MockCall! = .init()
    private lazy var mockAppState: MockAppStateAdapter! = .init()
    private lazy var subject: HLSStateAdapter! = .init { [made] url in
        let player = MockHLSPlayer()
        made.urls.append(url)
        made.players.append(player)
        return player
    }

    override func setUp() async throws {
        try await super.setUp()
        mockAppState.makeShared()
    }

    override func tearDown() async throws {
        mockAppState.dismante()
        mockAppState = nil
        subject = nil
        call = nil
        made.players = []
        made.urls = []
        try await super.tearDown()
    }

    // MARK: - player(for:)

    func test_player_whenTheCallPlaysHLS_createsAndStartsOnePlayer() {
        call.state.playbackType = .hls(url)

        let player = subject.player(for: call)

        XCTAssertNotNil(player)
        XCTAssertTrue(player === made.players.first)
        XCTAssertEqual(made.urls, [url])
        XCTAssertEqual(made.players.first?.playCount, 1)
    }

    func test_player_whenTheCallDoesNotPlayHLS_returnsNilAndCreatesNothing() {
        let player = subject.player(for: call)

        XCTAssertNil(player)
        XCTAssertTrue(made.players.isEmpty)
    }

    func test_player_twice_returnsTheSamePlayer() {
        call.state.playbackType = .hls(url)

        let first = subject.player(for: call)
        let second = subject.player(for: call)

        XCTAssertNotNil(first)
        XCTAssertTrue(first === second)
        XCTAssertEqual(made.players.count, 1)
    }

    func test_player_afterThePlaylistURLChanged_returnsAPlayerForTheNewURL() async {
        call.state.playbackType = .hls(url)
        let first = subject.player(for: call)
        call.state.playbackType = .hls(otherURL)

        let second = subject.player(for: call)

        XCTAssertNotNil(second)
        XCTAssertFalse(first === second)
        XCTAssertEqual(made.urls, [url, otherURL])
        XCTAssertEqual(made.players[0].pauseCount, 1)
    }

    func test_playlistURLChanged_withAPlayer_swapsItWithoutARequest() {
        call.state.playbackType = .hls(url)
        _ = subject.player(for: call)

        call.state.playbackType = .hls(otherURL)

        XCTAssertEqual(made.urls, [url, otherURL])
        XCTAssertEqual(made.players[0].pauseCount, 1)
    }

    func test_playlistURLChanged_withoutAPlayer_createsNothing() {
        call.state.playbackType = .hls(url)
        call.state.playbackType = .hls(otherURL)

        XCTAssertTrue(made.players.isEmpty)
    }

    // MARK: - free

    func test_playbackTypeBecomesWebRTC_stopsThePlayerAndReturnsNil() {
        call.state.playbackType = .hls(url)
        _ = subject.player(for: call)

        call.state.playbackType = .webRTC

        XCTAssertEqual(made.players.first?.pauseCount, 1)
        XCTAssertEqual(made.players.first?.replacedItems.count, 1)
        XCTAssertNil(subject.player(for: call))
    }

    func test_playbackTypeBecomesWebRTCRightAfterARequest_leavesNoPlayerPlaying() {
        call.state.playbackType = .hls(url)

        _ = subject.player(for: call)
        call.state.playbackType = .webRTC

        XCTAssertTrue(made.players.allSatisfy { $0.pauseCount == 1 })
    }

    func test_playbackTypeReturnsToHLS_afterTheCallLeftHLS_createsANewPlayer() {
        call.state.playbackType = .hls(url)
        _ = subject.player(for: call)
        call.state.playbackType = .webRTC

        call.state.playbackType = .hls(url)
        let player = subject.player(for: call)

        XCTAssertEqual(made.players.count, 2)
        XCTAssertTrue(player === made.players[1])
        XCTAssertEqual(made.players[1].pauseCount, 0)
    }

    func test_free_stopsThePlayer() {
        call.state.playbackType = .hls(url)
        _ = subject.player(for: call)

        subject.free()

        XCTAssertEqual(made.players.first?.pauseCount, 1)
        XCTAssertEqual(made.players.first?.replacedItems.count, 1)
    }

    func test_free_withoutAPlayer_doesNothing() {
        subject.free()

        XCTAssertTrue(made.players.isEmpty)
    }

    func test_player_afterFree_whileTheCallPlaysHLS_neverReturnsTheFreedPlayer() {
        call.state.playbackType = .hls(url)
        let freed = subject.player(for: call)
        subject.free()

        let player = subject.player(for: call)

        XCTAssertFalse(freed === player)
        XCTAssertEqual(made.players.count, 2)
        XCTAssertTrue(player === made.players[1])
        XCTAssertEqual(made.players[1].pauseCount, 0)
    }

    // MARK: - the host stops and starts the live

    func test_backstageBecomesTrue_stopsThePlayer() {
        call.state.playbackType = .hls(url)
        _ = subject.player(for: call)

        call.state.backstage = true

        XCTAssertEqual(made.players.first?.pauseCount, 1)
        XCTAssertEqual(made.players.first?.replacedItems.count, 1)
    }

    func test_player_whileTheCallIsBackstage_returnsNilAndCreatesNothing() {
        call.state.playbackType = .hls(url)
        call.state.backstage = true

        let player = subject.player(for: call)

        XCTAssertNil(player)
        XCTAssertTrue(made.players.isEmpty)
    }

    func test_backstageBecomesFalse_withTheSameURL_createsANewPlayerOnTheNextRequest() {
        call.state.playbackType = .hls(url)
        _ = subject.player(for: call)
        call.state.backstage = true

        call.state.backstage = false
        let player = subject.player(for: call)

        XCTAssertEqual(made.urls, [url, url])
        XCTAssertTrue(player === made.players[1])
        XCTAssertEqual(made.players[1].pauseCount, 0)
    }

    func test_hlsBroadcastingStopped_stopsThePlayerAndReturnsNil() {
        call.state.playbackType = .hls(url)
        _ = subject.player(for: call)

        call.state.updateState(from: makeHLSStoppedEvent())

        XCTAssertEqual(made.players.first?.pauseCount, 1)
        XCTAssertEqual(made.players.first?.replacedItems.count, 1)
        XCTAssertNil(subject.player(for: call))
        XCTAssertEqual(made.players.count, 1)
    }

    func test_hlsBroadcastingStarted_afterAStop_withANewURL_swapsToANewPlayer() {
        call.state.playbackType = .hls(url)
        _ = subject.player(for: call)
        call.state.updateState(from: makeHLSStoppedEvent())

        call.state.updateState(from: makeHLSStartedEvent(otherURL))
        let player = subject.player(for: call)

        XCTAssertEqual(made.urls, [url, otherURL])
        XCTAssertTrue(player === made.players[1])
    }

    func test_hlsBroadcastingStarted_withANewURL_swapsThePlayerOfTheCall() {
        call.state.playbackType = .hls(url)
        _ = subject.player(for: call)

        call.state.updateState(from: makeHLSStartedEvent(otherURL))

        XCTAssertEqual(made.urls, [url, otherURL])
        XCTAssertEqual(made.players[0].pauseCount, 1)
    }

    // MARK: - audio output

    func test_audioOutputOff_mutesThePlayerAndOnAgainUnmutesIt() async {
        let call = await makeCallWithAudioOutputOff()
        _ = subject.player(for: call)
        XCTAssertEqual(made.players.first?.isMuted, true)

        call.state.update(callSettings: .init(audioOutputOn: true))
        XCTAssertEqual(made.players.first?.isMuted, false)

        call.state.update(callSettings: .init(audioOutputOn: false))
        XCTAssertEqual(made.players.first?.isMuted, true)
    }

    func test_audioOutputChange_afterFree_doesNotTouchThePlayer() async {
        let call = await makeCallWithAudioOutputOff()
        _ = subject.player(for: call)
        subject.free()

        call.state.update(callSettings: .init(audioOutputOn: true))

        XCTAssertEqual(made.players.first?.isMuted, true)
    }

    // MARK: - Private Helpers

    private func makeHLSStoppedEvent() -> VideoEvent {
        .typeCallHLSBroadcastingStoppedEvent(
            .init(callCid: "livestream:1", createdAt: Date())
        )
    }

    private func makeHLSStartedEvent(_ url: URL) -> VideoEvent {
        .typeCallHLSBroadcastingStartedEvent(
            .init(
                call: .dummy(),
                callCid: "livestream:1",
                createdAt: Date(),
                hlsPlaylistUrl: url.absoluteString
            )
        )
    }

    /// A call that plays HLS, once its controller pushed the call settings.
    /// The controller pushes its own settings to the state when it is set up.
    /// Waiting for them keeps them from overwriting a value of the test.
    private func makeCallWithAudioOutputOff() async -> MockCall {
        let call = MockCall(
            .dummy(
                callController: MockCallController(
                    initialCallSettings: .init(audioOutputOn: false)
                )
            )
        )
        await fulfilmentInMainActor { !call.state.callSettings.audioOutputOn }
        call.state.playbackType = .hls(url)
        return call
    }
}
