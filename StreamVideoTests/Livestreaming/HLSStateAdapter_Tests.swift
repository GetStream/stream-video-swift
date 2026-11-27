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
    private lazy var subject: HLSStateAdapter! = .init { [made] _ in
        let player = MockHLSPlayer()
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
        try await super.tearDown()
    }

    // MARK: - player(for:)

    func test_player_whenTheCallPlaysHLS_createsAndStartsOnePlayer() async {
        call.state.playbackType = .hls(url)

        let player = await subject.player(for: call)

        XCTAssertNotNil(player)
        XCTAssertTrue(player === made.players.first)
        XCTAssertEqual(made.players.count, 1)
        XCTAssertEqual(made.players.first?.playCount, 1)
    }

    func test_player_whenTheCallDoesNotPlayHLS_returnsNilAndCreatesNothing() async {
        let player = await subject.player(for: call)

        XCTAssertNil(player)
        XCTAssertTrue(made.players.isEmpty)
    }

    func test_player_twice_returnsTheSamePlayer() async {
        call.state.playbackType = .hls(url)

        let first = await subject.player(for: call)
        let second = await subject.player(for: call)

        XCTAssertNotNil(first)
        XCTAssertTrue(first === second)
        XCTAssertEqual(made.players.count, 1)
    }

    func test_player_concurrently_createsOnePlayer() async {
        call.state.playbackType = .hls(url)

        async let first = subject.player(for: call)
        async let second = subject.player(for: call)
        let players = await [first, second]

        XCTAssertNotNil(players[0])
        XCTAssertTrue(players[0] === players[1])
        XCTAssertEqual(made.players.count, 1)
    }

    func test_player_afterThePlaylistURLChanged_returnsAPlayerForTheNewURL() async {
        call.state.playbackType = .hls(url)
        let first = await subject.player(for: call)
        call.state.playbackType = .hls(otherURL)

        let second = await subject.player(for: call)

        XCTAssertNotNil(second)
        XCTAssertFalse(first === second)
        XCTAssertEqual(made.players.count, 2)
        await fulfillment { [made] in made.players[0].pauseCount == 1 }
    }

    func test_playlistURLChanged_withAPlayer_swapsItWithoutARequest() async {
        call.state.playbackType = .hls(url)
        _ = await subject.player(for: call)

        call.state.playbackType = .hls(otherURL)

        await fulfillment { [made] in made.players.count == 2 }
        await fulfillment { [made] in made.players[0].pauseCount == 1 }
    }

    func test_playlistURLChanged_withoutAPlayer_createsNothing() async {
        call.state.playbackType = .hls(url)
        call.state.playbackType = .hls(otherURL)

        await wait(for: 0.2)

        XCTAssertTrue(made.players.isEmpty)
    }

    // MARK: - free

    func test_playbackTypeBecomesWebRTC_stopsThePlayerAndReturnsNil() async {
        call.state.playbackType = .hls(url)
        _ = await subject.player(for: call)

        call.state.playbackType = .webRTC

        await fulfillment { [made] in made.players.first?.pauseCount == 1 }
        XCTAssertEqual(made.players.first?.replacedItems.count, 1)
        let player = await subject.player(for: call)
        XCTAssertNil(player)
    }

    func test_playbackTypeReturnsToHLS_afterTheCallLeftHLS_createsANewPlayer() async {
        call.state.playbackType = .hls(url)
        _ = await subject.player(for: call)
        call.state.playbackType = .webRTC
        await fulfillment { [made] in made.players.first?.pauseCount == 1 }

        call.state.playbackType = .hls(url)
        let player = await subject.player(for: call)

        XCTAssertEqual(made.players.count, 2)
        XCTAssertTrue(player === made.players[1])
    }

    func test_free_stopsThePlayer() async {
        call.state.playbackType = .hls(url)
        _ = await subject.player(for: call)

        await subject.free()

        XCTAssertEqual(made.players.first?.pauseCount, 1)
        XCTAssertEqual(made.players.first?.replacedItems.count, 1)
    }

    func test_free_withoutAPlayer_doesNothing() async {
        await subject.free()

        XCTAssertTrue(made.players.isEmpty)
    }

    func test_player_afterFree_whileTheCallPlaysHLS_createsANewPlayer() async {
        call.state.playbackType = .hls(url)
        _ = await subject.player(for: call)
        await subject.free()

        let player = await subject.player(for: call)

        XCTAssertEqual(made.players.count, 2)
        XCTAssertTrue(player === made.players[1])
    }

    // MARK: - audio output

    func test_audioOutputOff_mutesThePlayerAndOnAgainUnmutesIt() async {
        let call = await makeCallWithAudioOutputOff()
        _ = await subject.player(for: call)
        XCTAssertEqual(made.players.first?.isMuted, true)

        call.state.update(callSettings: .init(audioOutputOn: true))
        XCTAssertEqual(made.players.first?.isMuted, false)

        call.state.update(callSettings: .init(audioOutputOn: false))
        XCTAssertEqual(made.players.first?.isMuted, true)
    }

    func test_audioOutputChange_afterFree_doesNotTouchThePlayer() async {
        let call = await makeCallWithAudioOutputOff()
        _ = await subject.player(for: call)
        await subject.free()

        call.state.update(callSettings: .init(audioOutputOn: true))

        XCTAssertEqual(made.players.first?.isMuted, true)
    }

    // MARK: - Private Helpers

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
