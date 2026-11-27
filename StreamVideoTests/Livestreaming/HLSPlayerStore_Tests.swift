//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamVideo
import XCTest

@MainActor
final class HLSPlayerStore_Tests: StreamVideoTestCase, @unchecked Sendable {

    private let url = URL(string: "https://example.com/live.m3u8")!
    private let made = MadePlayers()
    private lazy var subject: HLSPlayerStore! = .init { [made] url in
        let player = MockHLSPlayer()
        made.urls.append(url)
        made.players.append(player)
        return player
    }

    private lazy var mockAppState: MockAppStateAdapter! = .init()
    private var acquiredClaimId: UUID?

    override func tearDown() async throws {
        acquiredClaimId = nil
        mockAppState.dismante()
        mockAppState = nil
        subject = nil
        made.urls = []
        made.players = []
        try await super.tearDown()
    }

    // MARK: - acquire

    func test_acquire_hls_buildsAndStartsAPlayerForThePlaylist() async {
        let player = await subject.acquire(for: makeCall(), claimId: .init(), playbackType: .hls(url))

        XCTAssertNotNil(player)
        XCTAssertEqual(made.urls, [url])
        XCTAssertEqual(made.players.first?.playCount, 1)
    }

    func test_acquire_secondClaim_doesNotStartThePlayerAgain() async {
        let call = makeCall()
        _ = await subject.acquire(for: call, claimId: .init(), playbackType: .hls(url))

        _ = await subject.acquire(for: call, claimId: .init(), playbackType: .hls(url))

        XCTAssertEqual(made.players.first?.playCount, 1)
    }

    func test_acquire_webRTC_returnsNil() async {
        let call = makeCall()

        let acquired = await subject.acquire(for: call, claimId: .init(), playbackType: .webRTC)
        let player = await subject.player(for: call)

        XCTAssertNil(acquired)
        XCTAssertNil(player)
    }

    func test_acquire_twiceForTheSameCall_sharesOnePlayer() async {
        let call = makeCall()

        let first = await subject.acquire(for: call, claimId: .init(), playbackType: .hls(url))
        let second = await subject.acquire(for: call, claimId: .init(), playbackType: .hls(url))

        XCTAssertNotNil(first)
        XCTAssertTrue(first === second)
        XCTAssertEqual(made.urls.count, 1)
    }

    func test_acquire_concurrentFirstClaims_keepsOnePlayerPlaying() async {
        let call = makeCall()

        async let first = subject.acquire(for: call, claimId: .init(), playbackType: .hls(url))
        async let second = subject.acquire(for: call, claimId: .init(), playbackType: .hls(url))
        let players = await [first, second]

        XCTAssertTrue(players[0] === players[1])
        XCTAssertEqual(made.players.filter { $0.pauseCount == 0 }.count, 1)
    }

    func test_acquire_differentCalls_usesDifferentPlayers() async {
        let first = await subject.acquire(for: makeCall(), claimId: .init(), playbackType: .hls(url))
        let second = await subject.acquire(for: makeCall(), claimId: .init(), playbackType: .hls(url))

        XCTAssertFalse(first === second)
        XCTAssertEqual(made.players.map(\.pauseCount), [0, 0])
    }

    // MARK: - player(for:)

    func test_playerForCall_afterAcquire_returnsThePlayer() async throws {
        let call = makeCall()
        let acquired = try await acquire(for: call, .hls(url))
        let player = await subject.player(for: call)

        XCTAssertTrue(player === acquired.player)
    }

    func test_playerForCall_withoutAcquire_returnsNil() async {
        let player = await subject.player(for: makeCall())

        XCTAssertNil(player)
    }

    // MARK: - release

    func test_release_oneOfTwoClaims_keepsThePlayer() async throws {
        let call = makeCall()
        let first = try await acquire(for: call, .hls(url))
        _ = try await acquire(for: call, .hls(url))

        await subject.release(claimId: first.claimId, for: call)
        let player = await subject.player(for: call)

        XCTAssertNotNil(player)
        XCTAssertEqual(made.players.first?.pauseCount, 0)
    }

    func test_release_bothClaims_stopsAndEmptiesThePlayer() async throws {
        let call = makeCall()
        let first = try await acquire(for: call, .hls(url))
        let second = try await acquire(for: call, .hls(url))

        await subject.release(claimId: first.claimId, for: call)
        await subject.release(claimId: second.claimId, for: call)
        let player = await subject.player(for: call)

        XCTAssertNil(player)
        XCTAssertEqual(made.players.first?.pauseCount, 1)
        XCTAssertEqual(made.players.first?.replacedItems.count, 1)
        XCTAssertNil(made.players.first?.replacedItems.first ?? nil)
    }

    func test_release_sameClaimTwice_doesNotFreeThePlayerOfTheOtherClaim() async throws {
        let call = makeCall()
        let first = try await acquire(for: call, .hls(url))
        _ = try await acquire(for: call, .hls(url))

        await subject.release(claimId: first.claimId, for: call)
        await subject.release(claimId: first.claimId, for: call)
        let player = await subject.player(for: call)

        XCTAssertNotNil(player)
    }

    func test_acquire_afterTheLastRelease_createsANewPlayer() async throws {
        let call = makeCall()
        let first = try await acquire(for: call, .hls(url))
        await subject.release(claimId: first.claimId, for: call)

        let second = try await acquire(for: call, .hls(url))

        XCTAssertFalse(first.player === second.player)
        XCTAssertEqual(made.urls.count, 2)
    }

    // MARK: - playbackType

    func test_playbackTypeReturnsToWebRTC_freesThePlayer() async throws {
        let call = makeCall()
        _ = try await acquire(for: call, .hls(url))

        call.state.playbackType = .webRTC
        await waitUntilFreed(call)
        let player = await subject.player(for: call)

        XCTAssertEqual(made.players.first?.pauseCount, 1)
        XCTAssertNil(player)
    }

    func test_release_afterPlaybackTypeReturnedToWebRTC_doesNotFreeANewPlayer() async throws {
        let call = makeCall()
        let stale = try await acquire(for: call, .hls(url))
        call.state.playbackType = .webRTC
        await waitUntilFreed(call)
        call.state.playbackType = .hls(url)
        _ = try await acquire(for: call, .hls(url))

        await subject.release(claimId: stale.claimId, for: call)
        let player = await subject.player(for: call)

        XCTAssertNotNil(player)
    }

    func test_playbackTypeChangesToWebRTCWhileAcquiring_freesThePlayer() async {
        let call = makeCall()
        subject = HLSPlayerStore { [made] _ in
            MainActor.assumeIsolated { call.state.playbackType = .webRTC }
            let player = MockHLSPlayer()
            made.players.append(player)
            return player
        }

        _ = await subject.acquire(for: call, claimId: .init(), playbackType: .hls(url))

        await waitUntilFreed(call)
        XCTAssertEqual(made.players.first?.pauseCount, 1)
    }

    func test_playbackTypeObserver_doesNotKeepTheStoreAlive() async {
        let call = makeCall()
        nonisolated(unsafe) weak var weakStore: HLSPlayerStore?
        do {
            let store = HLSPlayerStore { MockHLSPlayer(playerItem: AVPlayerItem(url: $0)) }
            weakStore = store
            _ = await store.acquire(for: call, claimId: .init(), playbackType: .hls(url))
        }

        await fulfillment { weakStore == nil }
    }

    // MARK: - playlist change

    func test_acquire_withAnotherURL_replacesThePlayer() async throws {
        let call = makeCall()
        let other = URL(string: "https://example.com/other.m3u8")!
        let first = try await acquire(for: call, .hls(url))

        let second = try await acquire(for: call, .hls(other))
        let current = await subject.player(for: call)

        XCTAssertEqual(made.urls, [url, other])
        XCTAssertFalse(first.player === second.player)
        XCTAssertTrue(current === second.player)
        XCTAssertEqual(made.players.first?.pauseCount, 1)
    }

    func test_release_ofTheReplacedClaim_doesNotFreeTheNewPlayer() async throws {
        let call = makeCall()
        let other = URL(string: "https://example.com/other.m3u8")!
        let first = try await acquire(for: call, .hls(url))
        let second = try await acquire(for: call, .hls(other))

        await subject.release(claimId: first.claimId, for: call)
        let current = await subject.player(for: call)

        XCTAssertTrue(current === second.player)
    }

    // MARK: - audio output

    func test_acquire_audioOutputOff_startsAMutedPlayer() async throws {
        let call = makeCall()
        call.state.update(callSettings: .init(audioOutputOn: false))

        _ = try await acquire(for: call, .hls(url))

        XCTAssertEqual(made.players.first?.isMuted, true)
    }

    func test_acquire_audioOutputOn_startsAnUnmutedPlayer() async throws {
        _ = try await acquire(for: makeCall(), .hls(url))

        XCTAssertEqual(made.players.first?.isMuted, false)
    }

    func test_audioOutputChange_mutesAndUnmutesThePlayer() async throws {
        let call = makeCall()
        _ = try await acquire(for: call, .hls(url))

        call.state.update(callSettings: .init(audioOutputOn: false))
        XCTAssertEqual(made.players.first?.isMuted, true)

        call.state.update(callSettings: .init(audioOutputOn: true))
        XCTAssertEqual(made.players.first?.isMuted, false)
    }

    func test_audioOutputChange_afterThePlayerWasFreed_doesNotTouchIt() async throws {
        let call = makeCall()
        let acquired = try await acquire(for: call, .hls(url))
        await subject.release(claimId: acquired.claimId, for: call)

        call.state.update(callSettings: .init(audioOutputOn: false))

        XCTAssertEqual(made.players.first?.isMuted, false)
    }

    // MARK: - setPausedByUser

    func test_setPausedByUser_withAPlayer_returnsThePlayer() async throws {
        let call = makeCall()
        let acquired = try await acquire(for: call, .hls(url))

        let player = await subject.setPausedByUser(true, for: call)

        XCTAssertTrue(player === acquired.player)
    }

    func test_setPausedByUser_withoutAPlayer_returnsNil() async {
        let player = await subject.setPausedByUser(true, for: makeCall())

        XCTAssertNil(player)
    }

    // MARK: - resume after the system pauses the player

    func test_appBecomesActive_playerNotPausedByUser_resumesFromTheLiveEdge() async throws {
        let (_, player) = try await acquireLivePlayer()

        mockAppState.stubbedState = .background
        mockAppState.stubbedState = .foreground

        await fulfillment("The player did not resume.") { !player.seekTimes.isEmpty }
        XCTAssertEqual(player.seekTimes.last?.seconds, 94)
        XCTAssertEqual(player.playCount, 2)
    }

    func test_appBecomesActive_playerPlaying_doesNotResume() async throws {
        let (_, player) = try await acquireLivePlayer()
        player.stubbedRate = 1

        mockAppState.stubbedState = .background
        mockAppState.stubbedState = .foreground

        await wait(for: 0.3)
        XCTAssertTrue(player.seekTimes.isEmpty)
        XCTAssertEqual(player.playCount, 1)
    }

    func test_appBecomesActive_playerPausedByUser_staysPaused() async throws {
        let (call, player) = try await acquireLivePlayer()
        _ = await subject.setPausedByUser(true, for: call)

        mockAppState.stubbedState = .background
        mockAppState.stubbedState = .foreground

        await wait(for: 0.3)
        XCTAssertTrue(player.seekTimes.isEmpty)
        XCTAssertEqual(player.playCount, 1)
    }

    func test_appBecomesActive_userResumedAfterPausing_resumes() async throws {
        let (call, player) = try await acquireLivePlayer()
        _ = await subject.setPausedByUser(true, for: call)
        _ = await subject.setPausedByUser(false, for: call)

        mockAppState.stubbedState = .background
        mockAppState.stubbedState = .foreground

        await fulfillment("The player did not resume.") { !player.seekTimes.isEmpty }
        XCTAssertEqual(player.playCount, 2)
    }

    func test_interruptionEnded_shouldResume_resumesFromTheLiveEdge() async throws {
        let (_, player) = try await acquireLivePlayer()

        postInterruption(.ended, options: .shouldResume)

        await fulfillment("The player did not resume.") { !player.seekTimes.isEmpty }
        XCTAssertEqual(player.seekTimes.last?.seconds, 94)
        XCTAssertEqual(player.playCount, 2)
    }

    func test_interruptionEnded_withoutShouldResume_doesNotResume() async throws {
        let (_, player) = try await acquireLivePlayer()

        postInterruption(.ended, options: [])

        await wait(for: 0.3)
        XCTAssertTrue(player.seekTimes.isEmpty)
        XCTAssertEqual(player.playCount, 1)
    }

    func test_interruptionBegan_doesNotResume() async throws {
        let (_, player) = try await acquireLivePlayer()

        postInterruption(.began, options: .shouldResume)

        await wait(for: 0.3)
        XCTAssertTrue(player.seekTimes.isEmpty)
    }

    func test_appBecomesActive_afterTheEntryWasFreed_doesNotResume() async throws {
        let (call, player) = try await acquireLivePlayer()
        await subject.release(claimId: try XCTUnwrap(acquiredClaimId), for: call)
        await waitUntilFreed(call)
        let playCount = player.playCount

        mockAppState.stubbedState = .background
        mockAppState.stubbedState = .foreground
        postInterruption(.ended, options: .shouldResume)

        await wait(for: 0.3)
        XCTAssertTrue(player.seekTimes.isEmpty)
        XCTAssertEqual(player.playCount, playCount)
    }

    // MARK: - Private Helpers

    private func postInterruption(
        _ type: AVAudioSession.InterruptionType,
        options: AVAudioSession.InterruptionOptions
    ) {
        NotificationCenter.default.post(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [
                AVAudioSessionInterruptionTypeKey: type.rawValue,
                AVAudioSessionInterruptionOptionKey: options.rawValue
            ]
        )
    }

    /// Claims a player that plays a live item 90 seconds long, 6 seconds
    /// behind the edge when resumed. The player reports rate 0.
    private func acquireLivePlayer() async throws -> (Call, MockHLSPlayer) {
        let item = MockHLSPlayerItem(url: url)
        item.ranges = [CMTimeRange(
            start: CMTime(seconds: 10, preferredTimescale: 600),
            duration: CMTime(seconds: 90, preferredTimescale: 600)
        )]
        item.liveOffset = CMTime(seconds: 6, preferredTimescale: 600)
        mockAppState.makeShared()
        subject = HLSPlayerStore { [made] _ in
            let player = MockHLSPlayer(playerItem: item)
            made.players.append(player)
            return player
        }
        let call = makeCall()
        acquiredClaimId = try await acquire(for: call, .hls(url)).claimId
        return (call, try XCTUnwrap(made.players.first))
    }

    private func makeCall() -> Call {
        let call = MockCall(.dummy(callController: MockCallController()))
        call.state.playbackType = .hls(url)
        return call
    }

    private func acquire(
        for call: Call,
        _ playbackType: PlaybackType
    ) async throws -> (claimId: UUID, player: AVPlayer) {
        let claimId = UUID()
        let player = await subject.acquire(
            for: call,
            claimId: claimId,
            playbackType: playbackType
        )
        return (claimId, try XCTUnwrap(player))
    }

    private func waitUntilFreed(_ call: Call) async {
        await fulfillment { [subject] in await subject?.player(for: call) == nil }
    }
}
