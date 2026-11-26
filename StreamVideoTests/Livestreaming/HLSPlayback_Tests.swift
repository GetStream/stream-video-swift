//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamVideo
import XCTest

@MainActor
final class HLSPlayback_Tests: StreamVideoTestCase, @unchecked Sendable {

    private let url = URL(string: "https://example.com/live.m3u8")!
    private let made = MadePlayers()
    private lazy var call: MockCall! = .init()
    private lazy var store: HLSPlayerStore! = .init { [made] _ in
        let player = MockHLSPlayer()
        made.players.append(player)
        return player
    }

    private lazy var subject: HLSPlayback! = .init(call: call, store: store)

    private lazy var mockAppState: MockAppStateAdapter! = .init()

    override func tearDown() async throws {
        mockAppState.dismante()
        mockAppState = nil
        subject = nil
        store = nil
        call = nil
        made.players = []
        try await super.tearDown()
    }

    // MARK: - acquire

    func test_acquire_afterThePlaylistURLChanged_returnsAPlayerForTheNewURL() async {
        call.state.playbackType = .hls(url)
        let first = await subject.acquire()
        call.state.playbackType = .hls(URL(string: "https://example.com/other.m3u8")!)

        let second = await subject.acquire()

        XCTAssertNotNil(second)
        XCTAssertFalse(first === second)
        XCTAssertEqual(made.players.count, 2)
    }

    func test_acquire_whenTheCallPlaysHLS_returnsThePlayerOfTheCall() async {
        call.state.playbackType = .hls(url)

        let player = await subject.acquire()

        let stored = await store.player(for: call)
        XCTAssertNotNil(player)
        XCTAssertTrue(player === stored)
    }

    func test_acquire_whenTheCallDoesNotPlayHLS_returnsNil() async {
        let player = await subject.acquire()

        XCTAssertNil(player)
        let stored = await store.player(for: call)
        XCTAssertNil(stored)
    }

    func test_acquire_twice_returnsThePlayerAndTakesOneClaim() async {
        call.state.playbackType = .hls(url)

        let first = await subject.acquire()
        let second = await subject.acquire()
        await subject.release()

        XCTAssertTrue(first === second)
        let stored = await store.player(for: call)
        XCTAssertNil(stored)
    }

    func test_acquire_concurrently_takesOneClaim() async {
        call.state.playbackType = .hls(url)

        async let first = subject.acquire()
        async let second = subject.acquire()
        let players = await [first, second]

        XCTAssertNotNil(players[0])
        XCTAssertTrue(players[0] === players[1])
        await subject.release()
        let stored = await store.player(for: call)
        XCTAssertNil(stored)
    }

    func test_acquire_afterTheCallLeftHLS_dropsTheStaleClaim() async {
        call.state.playbackType = .hls(url)
        _ = await subject.acquire()
        call.state.playbackType = .webRTC
        await fulfillment { [store, call] in await store?.player(for: call!) == nil }

        let whileWebRTC = await subject.acquire()
        XCTAssertNil(whileWebRTC)

        call.state.playbackType = .hls(url)
        let afterHLS = await subject.acquire()
        XCTAssertEqual(made.players.count, 2)
        XCTAssertTrue(afterHLS === made.players[1])
    }

    // MARK: - release

    func test_release_withoutAClaim_doesNothing() async {
        await subject.release()

        XCTAssertTrue(made.players.isEmpty)
    }

    func test_release_givesTheClaimBack() async {
        call.state.playbackType = .hls(url)
        _ = await subject.acquire()

        await subject.release()

        let stored = await store.player(for: call)
        XCTAssertNil(stored)
    }

    // MARK: - setMuted

    func test_setMuted_mutesAndUnmutesThePlayer() async {
        call.state.playbackType = .hls(url)
        _ = await subject.acquire()

        await subject.setMuted(true)
        XCTAssertTrue(made.players[0].isMuted)

        await subject.setMuted(false)
        XCTAssertFalse(made.players[0].isMuted)
    }

    func test_setMuted_withoutAPlayer_doesNothing() async {
        await subject.setMuted(true)

        XCTAssertTrue(made.players.isEmpty)
    }

    func test_setMuted_afterTheStoreFreedThePlayer_actsOnTheNewPlayerOnly() async throws {
        call.state.playbackType = .hls(url)
        _ = await subject.acquire()
        call.state.playbackType = .webRTC
        await fulfillment { [store, call] in await store?.player(for: call!) == nil }
        call.state.playbackType = .hls(url)
        let claim = await store.acquire(for: call, claimId: .init(), playbackType: .hls(url))
        _ = try XCTUnwrap(claim)

        await subject.setMuted(true)

        XCTAssertFalse(made.players[0].isMuted)
        XCTAssertTrue(made.players[1].isMuted)
    }

    // MARK: - setPaused

    func test_setPaused_true_pausesThePlayer() async {
        call.state.playbackType = .hls(url)
        _ = await subject.acquire()

        await subject.setPaused(true)

        XCTAssertEqual(made.players[0].pauseCount, 1)
    }

    func test_setPaused_false_playsThePlayerAgain() async {
        call.state.playbackType = .hls(url)
        _ = await subject.acquire()
        let playCount = made.players[0].playCount

        await subject.setPaused(false)

        XCTAssertEqual(made.players[0].playCount, playCount + 1)
        XCTAssertEqual(made.players[0].pauseCount, 0)
    }

    // MARK: - setPaused(false) seeks to the live edge

    func test_setPaused_false_seeksBehindTheEndByTheRecommendedOffset() async {
        let item = liveItem(
            ranges: [CMTimeRange(start: seconds(10), duration: seconds(90))],
            offset: seconds(6)
        )
        let playback = await acquireLivePlayer(item)

        await playback.setPaused(false)

        XCTAssertEqual(made.players[0].seekTimes.last?.seconds, 94)
    }

    func test_setPaused_false_offsetLargerThanTheRange_clampsToTheStart() async {
        let item = liveItem(
            ranges: [CMTimeRange(start: seconds(10), duration: seconds(20))],
            offset: seconds(100)
        )
        let playback = await acquireLivePlayer(item)

        await playback.setPaused(false)

        XCTAssertEqual(made.players[0].seekTimes.last?.seconds, 10)
    }

    func test_setPaused_false_invalidOffset_seeksToTheEnd() async {
        let item = liveItem(
            ranges: [CMTimeRange(start: seconds(0), duration: seconds(50))],
            offset: .invalid
        )
        let playback = await acquireLivePlayer(item)

        await playback.setPaused(false)

        XCTAssertEqual(made.players[0].seekTimes.last?.seconds, 50)
    }

    func test_setPaused_false_invalidRange_doesNotSeek() async {
        let item = liveItem(ranges: [.invalid], offset: seconds(6))
        let playback = await acquireLivePlayer(item)

        await playback.setPaused(false)

        XCTAssertTrue(made.players[0].seekTimes.isEmpty)
    }

    // MARK: - Private Helpers

    private func seconds(_ value: Double) -> CMTime {
        CMTime(seconds: value, preferredTimescale: 600)
    }

    private func liveItem(ranges: [CMTimeRange], offset: CMTime) -> MockHLSPlayerItem {
        let item = MockHLSPlayerItem(url: url)
        item.ranges = ranges
        item.liveOffset = offset
        return item
    }

    /// Claims a player that plays `item`, so the controls act on it.
    private func acquireLivePlayer(_ item: MockHLSPlayerItem) async -> HLSPlayback {
        let liveStore = HLSPlayerStore { [made] _ in
            let player = MockHLSPlayer(playerItem: item)
            made.players.append(player)
            return player
        }
        call.state.playbackType = .hls(url)
        let playback = HLSPlayback(call: call, store: liveStore)
        _ = await playback.acquire()
        return playback
    }
}
