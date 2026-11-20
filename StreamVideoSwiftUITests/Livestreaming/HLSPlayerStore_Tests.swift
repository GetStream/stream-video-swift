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
    private let made = MadePlayers()
    private lazy var subject: HLSPlayerStore! = .init { [made] url in
        let player = HLSSpyPlayer()
        made.urls.append(url)
        made.players.append(player)
        return player
    }

    override func tearDown() async throws {
        subject = nil
        made.urls = []
        made.players = []
        try await super.tearDown()
    }

    // MARK: - acquire

    func test_acquire_hls_buildsAPlayerForThePlaylist() async {
        let lease = await subject.acquire(for: makeCall(), playbackType: .hls(url))

        XCTAssertNotNil(lease)
        XCTAssertEqual(made.urls, [url])
    }

    func test_acquire_firstClaim_startsThePlayer() async {
        _ = await subject.acquire(for: makeCall(), playbackType: .hls(url))

        XCTAssertEqual(made.players.first?.playCount, 1)
    }

    func test_acquire_secondClaim_doesNotStartThePlayerAgain() async {
        let call = makeCall()
        _ = await subject.acquire(for: call, playbackType: .hls(url))

        _ = await subject.acquire(for: call, playbackType: .hls(url))

        XCTAssertEqual(made.players.first?.playCount, 1)
    }

    func test_acquire_webRTC_returnsNil() async {
        let lease = await subject.acquire(for: makeCall(), playbackType: .webRTC)
        let count = await subject.activePlayerCount

        XCTAssertNil(lease)
        XCTAssertEqual(count, 0)
    }

    func test_acquire_withASender_sendsStarted() async {
        let recorder = ReportRecorder()
        let call = makeCall()
        await call.callController.hlsCoordinator.stateAdapter
            .setStatsDelivering(recorder)
        call.state.session = CallSessionResponse(
            acceptedBy: [:],
            anonymousParticipantCount: 0,
            id: "session-1",
            missedBy: [:],
            participants: [],
            participantsCountByRole: [:],
            rejectedBy: [:]
        )

        _ = await subject.acquire(for: call, playbackType: .hls(url))

        let started = expectation(description: "started")
        Task {
            while await recorder.reports.isEmpty {
                try? await Task.sleep(nanoseconds: 20_000_000)
            }
            started.fulfill()
        }
        await fulfillment(of: [started], timeout: 2)
        let report = await recorder.reports.first
        let unifiedSessionId = await call.callController.hlsCoordinator
            .stateAdapter.unifiedSessionId
        XCTAssertEqual(report?.type, "started")
        XCTAssertEqual(report?.unifiedSessionId, unifiedSessionId)
    }

    func test_acquire_twiceForTheSameCall_sharesOnePlayer() async {
        let call = makeCall()

        let first = await subject.acquire(for: call, playbackType: .hls(url))
        let second = await subject.acquire(for: call, playbackType: .hls(url))

        XCTAssertNotNil(first)
        XCTAssertTrue(first?.player === second?.player)
        XCTAssertEqual(made.urls.count, 1)
    }

    func test_acquire_differentCalls_usesDifferentPlayers() async {
        let first = await subject.acquire(for: makeCall(), playbackType: .hls(url))
        let second = await subject.acquire(for: makeCall(), playbackType: .hls(url))
        let count = await subject.activePlayerCount

        XCTAssertFalse(first?.player === second?.player)
        XCTAssertEqual(count, 2)
    }

    // MARK: - player(for:)

    func test_playerForCall_afterAcquire_returnsThePlayer() async throws {
        let call = makeCall()
        let unwrapped0 = await subject.acquire(for: call, playbackType: .hls(url))
        let lease = try XCTUnwrap(unwrapped0)
        let player = await subject.player(for: call)

        XCTAssertTrue(player === lease.player)
    }

    func test_playerForCall_withoutAcquire_returnsNil() async {
        let player = await subject.player(for: makeCall())

        XCTAssertNil(player)
    }

    // MARK: - release

    func test_release_oneOfTwoLeases_keepsThePlayer() async throws {
        let call = makeCall()
        let unwrapped1 = await subject.acquire(for: call, playbackType: .hls(url))
        let first = try XCTUnwrap(unwrapped1)
        _ = await subject.acquire(for: call, playbackType: .hls(url))

        await first.release()
        let count = await subject.activePlayerCount

        XCTAssertEqual(count, 1)
        XCTAssertEqual(made.players.first?.pauseCount, 0)
    }

    func test_release_bothLeases_stopsAndEmptiesThePlayer() async throws {
        let call = makeCall()
        let unwrapped2 = await subject.acquire(for: call, playbackType: .hls(url))
        let first = try XCTUnwrap(unwrapped2)
        let unwrapped3 = await subject.acquire(for: call, playbackType: .hls(url))
        let second = try XCTUnwrap(unwrapped3)

        await first.release()
        await second.release()
        let count = await subject.activePlayerCount

        XCTAssertEqual(count, 0)
        XCTAssertEqual(made.players.first?.pauseCount, 1)
        XCTAssertEqual(made.players.first?.replacedItems.count, 1)
        XCTAssertNil(made.players.first?.replacedItems.first ?? nil)
    }

    func test_release_sameLeaseTwice_doesNotFreeThePlayerOfTheOtherLease() async throws {
        let call = makeCall()
        let unwrapped4 = await subject.acquire(for: call, playbackType: .hls(url))
        let first = try XCTUnwrap(unwrapped4)
        _ = await subject.acquire(for: call, playbackType: .hls(url))

        await first.release()
        await first.release()
        let count = await subject.activePlayerCount

        XCTAssertEqual(count, 1)
    }

    func test_acquire_afterTheLastRelease_createsANewPlayer() async throws {
        let call = makeCall()
        let unwrapped5 = await subject.acquire(for: call, playbackType: .hls(url))
        let first = try XCTUnwrap(unwrapped5)
        await first.release()

        let unwrapped6 = await subject.acquire(for: call, playbackType: .hls(url))
        let second = try XCTUnwrap(unwrapped6)

        XCTAssertFalse(first.player === second.player)
        XCTAssertEqual(made.urls.count, 2)
    }

    // MARK: - playbackType

    func test_playbackTypeReturnsToWebRTC_freesThePlayer() async throws {
        let call = makeCall()
        let unwrapped7 = await subject.acquire(for: call, playbackType: .hls(url))
        _ = try XCTUnwrap(unwrapped7)

        call.state.playbackType = .webRTC
        await waitForPlayerCount(0)
        let player = await subject.player(for: call)

        XCTAssertEqual(made.players.first?.pauseCount, 1)
        XCTAssertNil(player)
    }

    func test_release_afterPlaybackTypeReturnedToWebRTC_doesNotFreeANewPlayer() async throws {
        let call = makeCall()
        let unwrapped8 = await subject.acquire(for: call, playbackType: .hls(url))
        let stale = try XCTUnwrap(unwrapped8)
        call.state.playbackType = .webRTC
        await waitForPlayerCount(0)
        let unwrapped9 = await subject.acquire(for: call, playbackType: .hls(url))
        _ = try XCTUnwrap(unwrapped9)

        await stale.release()
        let count = await subject.activePlayerCount

        XCTAssertEqual(count, 1)
    }

    // MARK: - Private Helpers

    private func makeCall() -> Call {
        let call = MockCall()
        call.state.playbackType = .hls(url)
        return call
    }

    private func waitForPlayerCount(_ count: Int) async {
        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            if await subject.activePlayerCount == count { return }
            await Task.yield()
        }
        let actual = await subject.activePlayerCount
        XCTAssertEqual(actual, count)
    }
}

private final class MadePlayers: @unchecked Sendable {
    var urls: [URL] = []
    var players: [HLSSpyPlayer] = []
}

private actor ReportRecorder: HLSStatsDelivering {
    private(set) var reports: [HLSStatsReport] = []

    func deliver(
        callType _: String,
        callId _: String,
        report: HLSStatsReport
    ) async throws {
        reports.append(report)
    }
}
