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
    private nonisolated(unsafe) var mockAPI: MockDefaultAPIEndpoints! = .init()
    private lazy var call: MockCall! = .init(
        .dummy(callController: MockCallController(defaultAPI: mockAPI))
    )
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
        mockAPI = nil
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

    // MARK: - stats

    func test_player_withStatsAndAPlayingPlayer_sendsStarted() async throws {
        makeStatsCall()

        _ = subject.player(for: call)
        let player = try XCTUnwrap(made.players.first)
        XCTAssertEqual(sentReports().count, 0)
        player.simulate(.playing)

        await fulfillment { self.sentReports().count == 1 }
        let report = try XCTUnwrap(sentReports().first)
        XCTAssertEqual(report.type, .started)
        XCTAssertEqual(report.statsToken, "token-1")
        XCTAssertFalse(report.unifiedSessionId.isEmpty)
    }

    func test_player_withoutAStatsToken_sendsNothing() async throws {
        call.state.playbackType = .hls(url)

        _ = subject.player(for: call)
        try XCTUnwrap(made.players.first).simulate(.playing)
        subject.free()
        await wait(for: 0.2)

        XCTAssertTrue(sentReports().isEmpty)
    }

    func test_playlistURLChanged_reportsTheNewPlaybackWithItsOwnSession() async throws {
        makeStatsCall()
        _ = subject.player(for: call)
        made.players[0].simulate(.playing)
        await fulfillment { self.sentReports().count == 1 }

        call.state.playbackType = .hls(otherURL)
        _ = subject.player(for: call)
        made.players[1].simulate(.playing)

        await fulfillment { self.sentReports().filter { $0.type == .started }.count == 2 }
        let sessions = Set(sentReports().filter { $0.type == .started }.map(\.userSessionId))
        XCTAssertEqual(sessions.count, 2)
        XCTAssertEqual(sentReports().filter { $0.type == .ended }.count, 1)
    }

    func test_playbackTypeBecomesWebRTC_sendsEnded() async {
        makeStatsCall()
        _ = subject.player(for: call)
        made.players[0].simulate(.playing)
        await fulfillment { self.sentReports().count == 1 }

        call.state.playbackType = .webRTC

        await fulfillment { self.sentReports().last?.type == .ended }
    }

    func test_free_sendsTheFinalStatsOfThePlayerItemWithEnded() async throws {
        let item = MockHLSPlayerItem(url: url)
        item.size = CGSize(width: 1280, height: 720)
        // Only `stubbedItem` holds the item, and `invalidate()` clears it. A
        // final read after `invalidate()` finds no item.
        subject = HLSStateAdapter { [made] _ in
            let player = MockHLSPlayer()
            player.stubbedItem = item
            made.players.append(player)
            return player
        }
        makeStatsCall()
        _ = subject.player(for: call)
        made.players[0].simulate(.playing)
        await fulfillment { self.sentReports().count == 1 }

        subject.free()

        await fulfillment { self.sentReports().last?.type == .ended }
        let final = try XCTUnwrap(sentReports().last)
        XCTAssertEqual(final.stats?.width, 1280)
        XCTAssertEqual(final.stats?.height, 720)
    }

    func test_free_whileTheStatsDeliveryHangs_stillStopsThePlayer() async {
        // The report never finishes in this test. A free that waits for it
        // leaves the player running, and the wait below times out.
        mockAPI.reportHLSStatsHandler = { try? await Task.sleep(nanoseconds: 60_000_000_000) }
        makeStatsCall()
        _ = subject.player(for: call)
        made.players[0].simulate(.playing)
        await fulfillment { self.sentReports().count == 1 }

        subject.free()

        await fulfillment { [made] in made.players[0].pauseCount == 1 }
    }

    func test_backstageBecomesTrue_sendsEnded() async {
        makeStatsCall()
        _ = subject.player(for: call)
        made.players[0].simulate(.playing)
        await fulfillment { self.sentReports().count == 1 }

        call.state.backstage = true

        await fulfillment { self.sentReports().last?.type == .ended }
    }

    func test_hlsBroadcastingStopped_sendsEnded() async {
        makeStatsCall()
        _ = subject.player(for: call)
        made.players[0].simulate(.playing)
        await fulfillment { self.sentReports().count == 1 }

        call.state.updateState(from: .typeCallHLSBroadcastingStoppedEvent(
            .init(callCid: "livestream:1", createdAt: Date())
        ))

        await fulfillment { self.sentReports().last?.type == .ended }
    }

    func test_free_withStats_mutesThePlayerAtOnce() {
        makeStatsCall()
        _ = subject.player(for: call)

        subject.free()

        // The final stats are read before the player stops. The old player
        // must not play audio over a new one meanwhile.
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

    /// Gives the call a join response and a session, so it reports playback.
    private func makeStatsCall() {
        mockAPI.stub(for: .reportHLSStats, with: ReportHLSStatsResponse(duration: "1ms"))
        call.state.update(
            from: JoinCallResponse.dummyHLSGrant(
                playback: .dummy(statsToken: "token-1")
            )
        )
        call.state.playbackType = .hls(url)
        call.state.session = CallSessionResponse(
            acceptedBy: [:],
            anonymousParticipantCount: 0,
            id: "session-1",
            missedBy: [:],
            participants: [],
            participantsCountByRole: [:],
            rejectedBy: [:]
        )
    }

    private nonisolated func sentReports() -> [ReportHLSStatsRequest] {
        mockAPI
            .recordedInputPayload(
                (String, String, ReportHLSStatsRequest).self,
                for: .reportHLSStats
            )?
            .map(\.2) ?? []
    }
}
