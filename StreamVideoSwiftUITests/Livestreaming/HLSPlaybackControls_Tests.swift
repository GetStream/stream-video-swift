//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class HLSPlaybackControls_Tests: StreamVideoTestCase, @unchecked Sendable {

    private let url = URL(string: "https://example.com/live.m3u8")!
    private let made = MadePlayers()
    private lazy var call: MockCall! = .init()
    private lazy var store: HLSPlayerStore! = .init { [made] _ in
        let player = HLSSpyPlayer()
        made.players.append(player)
        return player
    }

    private lazy var subject: HLSPlaybackControls! = .init(call: call, store: store)

    override func tearDown() async throws {
        subject = nil
        store = nil
        call = nil
        made.players = []
        try await super.tearDown()
    }

    // MARK: - init

    func test_init_withoutAStore_usesTheInjectedStore() async throws {
        let injected = HLSPlayerStore { [made] _ in
            let player = HLSSpyPlayer()
            made.players.append(player)
            return player
        }
        let previous = InjectedValues[\.hlsPlayerStore]
        InjectedValues[\.hlsPlayerStore] = injected
        defer { InjectedValues[\.hlsPlayerStore] = previous }
        let controls = HLSPlaybackControls(call: call)

        let unwrapped0 = await injected.acquire(for: call, playbackType: .hls(url))
        let lease = try XCTUnwrap(unwrapped0)
        let player = await controls.player()

        XCTAssertTrue(player === lease.player)
    }

    // MARK: - player

    func test_player_withoutAClaim_isNil() async {
        let player = await subject.player()

        XCTAssertNil(player)
    }

    func test_player_afterAClaim_isThePlayerOfTheCall() async throws {
        let unwrapped1 = await store.acquire(for: call, playbackType: .hls(url))
        let lease = try XCTUnwrap(unwrapped1)
        let player = await subject.player()

        XCTAssertTrue(player === lease.player)
    }

    func test_player_afterTheStoreFreedIt_isNilUntilTheCallPlaysHLSAgain() async throws {
        let unwrapped2 = await store.acquire(for: call, playbackType: .hls(url))
        let first = try XCTUnwrap(unwrapped2)
        call.state.playbackType = .webRTC
        await waitUntilPlayerIsNil()

        let unwrapped3 = await store.acquire(for: call, playbackType: .hls(url))
        let second = try XCTUnwrap(unwrapped3)
        let player = await subject.player()

        XCTAssertFalse(first.player === second.player)
        XCTAssertTrue(player === second.player)
    }

    func test_setMuted_afterTheStoreFreedThePlayer_actsOnTheNewPlayerOnly() async throws {
        let unwrapped4 = await store.acquire(for: call, playbackType: .hls(url))
        _ = try XCTUnwrap(unwrapped4)
        call.state.playbackType = .webRTC
        await waitUntilPlayerIsNil()
        let unwrapped5 = await store.acquire(for: call, playbackType: .hls(url))
        _ = try XCTUnwrap(unwrapped5)

        await subject.setMuted(true)

        XCTAssertFalse(made.players[0].isMuted)
        XCTAssertTrue(made.players[1].isMuted)
    }

    // MARK: - setMuted

    func test_setMuted_mutesAndUnmutesThePlayer() async throws {
        let unwrapped6 = await store.acquire(for: call, playbackType: .hls(url))
        _ = try XCTUnwrap(unwrapped6)

        await subject.setMuted(true)
        XCTAssertTrue(made.players[0].isMuted)

        await subject.setMuted(false)
        XCTAssertFalse(made.players[0].isMuted)
    }

    func test_setMuted_withoutAPlayer_doesNothing() async {
        await subject.setMuted(true)

        XCTAssertTrue(made.players.isEmpty)
    }

    // MARK: - setPaused

    func test_setPaused_true_pausesThePlayer() async throws {
        let unwrapped7 = await store.acquire(for: call, playbackType: .hls(url))
        _ = try XCTUnwrap(unwrapped7)

        await subject.setPaused(true)

        XCTAssertEqual(made.players[0].pauseCount, 1)
    }

    func test_setPaused_false_playsThePlayerAgain() async throws {
        let unwrapped8 = await store.acquire(for: call, playbackType: .hls(url))
        _ = try XCTUnwrap(unwrapped8)
        let playCount = made.players[0].playCount

        await subject.setPaused(false)

        XCTAssertEqual(made.players[0].playCount, playCount + 1)
        XCTAssertEqual(made.players[0].pauseCount, 0)
    }

    // MARK: - liveEdgeTarget

    func test_liveEdgeTarget_subtractsTheRecommendedOffsetFromTheEnd() {
        let range = CMTimeRange(start: seconds(10), duration: seconds(90))

        let target = HLSPlaybackControls.liveEdgeTarget(
            in: range,
            recommendedOffset: seconds(6)
        )

        XCTAssertEqual(target?.seconds, 94)
    }

    func test_liveEdgeTarget_offsetLargerThanTheRange_clampsToTheStart() {
        let range = CMTimeRange(start: seconds(10), duration: seconds(20))

        let target = HLSPlaybackControls.liveEdgeTarget(
            in: range,
            recommendedOffset: seconds(100)
        )

        XCTAssertEqual(target?.seconds, 10)
    }

    func test_liveEdgeTarget_invalidOffset_usesTheEnd() {
        let range = CMTimeRange(start: seconds(0), duration: seconds(50))

        let target = HLSPlaybackControls.liveEdgeTarget(
            in: range,
            recommendedOffset: .invalid
        )

        XCTAssertEqual(target?.seconds, 50)
    }

    func test_liveEdgeTarget_invalidRange_returnsNil() {
        XCTAssertNil(
            HLSPlaybackControls.liveEdgeTarget(
                in: .invalid,
                recommendedOffset: seconds(6)
            )
        )
    }

    // MARK: - Private Helpers

    private func seconds(_ value: Double) -> CMTime {
        CMTime(seconds: value, preferredTimescale: 600)
    }

    private func waitUntilPlayerIsNil() async {
        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            if await store.player(for: call) == nil { return }
            await Task.yield()
        }
        let player = await store.player(for: call)
        XCTAssertNil(player)
    }
}

private final class MadePlayers: @unchecked Sendable {
    var players: [HLSSpyPlayer] = []
}
