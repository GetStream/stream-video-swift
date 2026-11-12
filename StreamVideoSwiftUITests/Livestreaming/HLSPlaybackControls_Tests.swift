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
    private var madePlayers: [HLSSpyPlayer] = []
    private lazy var call: MockCall! = .init()
    private lazy var store: HLSPlayerStore! = .init { [unowned self] _ in
        let player = HLSSpyPlayer()
        madePlayers.append(player)
        return player
    }

    private lazy var subject: HLSPlaybackControls! = .init(call: call, store: store)

    override func tearDown() async throws {
        subject = nil
        store = nil
        call = nil
        madePlayers = []
        try await super.tearDown()
    }

    // MARK: - player

    func test_player_withoutAClaim_isNil() {
        XCTAssertNil(subject.player)
    }

    func test_player_afterAClaim_isThePlayerOfTheCall() throws {
        let lease = try XCTUnwrap(store.acquire(for: call, playbackType: .hls(url)))

        XCTAssertTrue(subject.player === lease.player)
    }

    func test_player_afterTheStoreFreedIt_isNilUntilTheCallPlaysHLSAgain() throws {
        let first = try XCTUnwrap(store.acquire(for: call, playbackType: .hls(url)))
        call.state.playbackType = .webRTC
        XCTAssertNil(subject.player)

        let second = try XCTUnwrap(store.acquire(for: call, playbackType: .hls(url)))

        XCTAssertFalse(first.player === second.player)
        XCTAssertTrue(subject.player === second.player)
    }

    func test_setMuted_afterTheStoreFreedThePlayer_actsOnTheNewPlayerOnly() throws {
        _ = try XCTUnwrap(store.acquire(for: call, playbackType: .hls(url)))
        call.state.playbackType = .webRTC
        _ = try XCTUnwrap(store.acquire(for: call, playbackType: .hls(url)))

        subject.setMuted(true)

        XCTAssertFalse(madePlayers[0].isMuted)
        XCTAssertTrue(madePlayers[1].isMuted)
    }

    // MARK: - setMuted

    func test_setMuted_mutesAndUnmutesThePlayer() throws {
        _ = try XCTUnwrap(store.acquire(for: call, playbackType: .hls(url)))

        subject.setMuted(true)
        XCTAssertTrue(madePlayers[0].isMuted)

        subject.setMuted(false)
        XCTAssertFalse(madePlayers[0].isMuted)
    }

    func test_setMuted_withoutAPlayer_doesNothing() {
        subject.setMuted(true)

        XCTAssertTrue(madePlayers.isEmpty)
    }

    // MARK: - setPaused

    func test_setPaused_true_pausesThePlayer() throws {
        _ = try XCTUnwrap(store.acquire(for: call, playbackType: .hls(url)))

        subject.setPaused(true)

        XCTAssertEqual(madePlayers[0].pauseCount, 1)
    }

    func test_setPaused_false_playsThePlayerAgain() throws {
        _ = try XCTUnwrap(store.acquire(for: call, playbackType: .hls(url)))
        let playCount = madePlayers[0].playCount

        subject.setPaused(false)

        XCTAssertEqual(madePlayers[0].playCount, playCount + 1)
        XCTAssertEqual(madePlayers[0].pauseCount, 0)
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
}
