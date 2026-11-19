//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class HLSPlayerStore_Tests: StreamVideoTestCase, @unchecked Sendable {

    private let url = URL(string: "https://example.com/live.m3u8")!
    private var madeURLs: [URL] = []
    private var madePlayers: [HLSSpyPlayer] = []
    private lazy var subject: HLSPlayerStore! = .init { [unowned self] url in
        let player = HLSSpyPlayer()
        madeURLs.append(url)
        madePlayers.append(player)
        return player
    }

    override func tearDown() async throws {
        subject = nil
        madeURLs = []
        madePlayers = []
        try await super.tearDown()
    }

    // MARK: - acquire

    func test_acquire_hls_buildsAPlayerForThePlaylist() {
        let lease = subject.acquire(for: makeCall(), playbackType: .hls(url))

        XCTAssertNotNil(lease)
        XCTAssertEqual(madeURLs, [url])
    }

    func test_acquire_firstClaim_startsThePlayer() {
        _ = subject.acquire(for: makeCall(), playbackType: .hls(url))

        XCTAssertEqual(madePlayers.first?.playCount, 1)
    }

    func test_acquire_secondClaim_doesNotStartThePlayerAgain() {
        let call = makeCall()
        _ = subject.acquire(for: call, playbackType: .hls(url))

        _ = subject.acquire(for: call, playbackType: .hls(url))

        XCTAssertEqual(madePlayers.first?.playCount, 1)
    }

    func test_acquire_webRTC_returnsNil() {
        XCTAssertNil(subject.acquire(for: makeCall(), playbackType: .webRTC))
        XCTAssertEqual(subject.activePlayerCount, 0)
    }

    func test_acquire_twiceForTheSameCall_sharesOnePlayer() {
        let call = makeCall()

        let first = subject.acquire(for: call, playbackType: .hls(url))
        let second = subject.acquire(for: call, playbackType: .hls(url))

        XCTAssertNotNil(first)
        XCTAssertTrue(first?.player === second?.player)
        XCTAssertEqual(madeURLs.count, 1)
    }

    func test_acquire_differentCalls_usesDifferentPlayers() {
        let first = subject.acquire(for: makeCall(), playbackType: .hls(url))
        let second = subject.acquire(for: makeCall(), playbackType: .hls(url))

        XCTAssertFalse(first?.player === second?.player)
        XCTAssertEqual(subject.activePlayerCount, 2)
    }

    // MARK: - player(for:)

    func test_playerForCall_afterAcquire_returnsThePlayer() throws {
        let call = makeCall()
        let lease = try XCTUnwrap(subject.acquire(for: call, playbackType: .hls(url)))

        XCTAssertTrue(subject.player(for: call) === lease.player)
    }

    func test_playerForCall_withoutAcquire_returnsNil() {
        XCTAssertNil(subject.player(for: makeCall()))
    }

    // MARK: - release

    func test_release_oneOfTwoLeases_keepsThePlayer() throws {
        let call = makeCall()
        let first = try XCTUnwrap(subject.acquire(for: call, playbackType: .hls(url)))
        _ = subject.acquire(for: call, playbackType: .hls(url))

        first.release()

        XCTAssertEqual(subject.activePlayerCount, 1)
        XCTAssertEqual(madePlayers.first?.pauseCount, 0)
    }

    func test_release_bothLeases_stopsAndEmptiesThePlayer() throws {
        let call = makeCall()
        let first = try XCTUnwrap(subject.acquire(for: call, playbackType: .hls(url)))
        let second = try XCTUnwrap(subject.acquire(for: call, playbackType: .hls(url)))

        first.release()
        second.release()

        XCTAssertEqual(subject.activePlayerCount, 0)
        XCTAssertEqual(madePlayers.first?.pauseCount, 1)
        XCTAssertEqual(madePlayers.first?.replacedItems.count, 1)
        XCTAssertNil(madePlayers.first?.replacedItems.first ?? nil)
    }

    func test_release_sameLeaseTwice_doesNotFreeThePlayerOfTheOtherLease() throws {
        let call = makeCall()
        let first = try XCTUnwrap(subject.acquire(for: call, playbackType: .hls(url)))
        _ = subject.acquire(for: call, playbackType: .hls(url))

        first.release()
        first.release()

        XCTAssertEqual(subject.activePlayerCount, 1)
    }

    func test_acquire_afterTheLastRelease_createsANewPlayer() throws {
        let call = makeCall()
        let first = try XCTUnwrap(subject.acquire(for: call, playbackType: .hls(url)))
        first.release()

        let second = try XCTUnwrap(subject.acquire(for: call, playbackType: .hls(url)))

        XCTAssertFalse(first.player === second.player)
        XCTAssertEqual(madeURLs.count, 2)
    }

    // MARK: - playbackType

    func test_playbackTypeReturnsToWebRTC_freesThePlayer() throws {
        let call = makeCall()
        _ = try XCTUnwrap(subject.acquire(for: call, playbackType: .hls(url)))

        call.state.playbackType = .webRTC

        XCTAssertEqual(subject.activePlayerCount, 0)
        XCTAssertEqual(madePlayers.first?.pauseCount, 1)
        XCTAssertNil(subject.player(for: call))
    }

    func test_release_afterPlaybackTypeReturnedToWebRTC_doesNotFreeANewPlayer() throws {
        let call = makeCall()
        let stale = try XCTUnwrap(subject.acquire(for: call, playbackType: .hls(url)))
        call.state.playbackType = .webRTC
        _ = try XCTUnwrap(subject.acquire(for: call, playbackType: .hls(url)))

        stale.release()

        XCTAssertEqual(subject.activePlayerCount, 1)
    }

    // MARK: - Private Helpers

    private func makeCall() -> Call {
        let call = MockCall()
        call.state.playbackType = .hls(url)
        return call
    }
}
