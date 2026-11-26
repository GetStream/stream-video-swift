//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import UIKit
import XCTest

@MainActor
final class HLSVideoRenderer_Tests: StreamVideoTestCase, @unchecked Sendable {

    private let url = URL(string: "https://example.com/live.m3u8")!
    private let made = MadePlayers()
    private lazy var call: MockCall! = .init()
    private lazy var store: HLSPlayerStore! = .init { [made] _ in
        let player = MockHLSPlayer()
        made.players.append(player)
        return player
    }

    private lazy var view: HLSPlayerView! = .init()
    private lazy var subject: HLSVideoRenderer.Representable.Coordinator! = .init(call: call)
    private var previousStore: HLSPlayerStore?
    @Atomic private var readyCount = 0

    override func setUp() async throws {
        try await super.setUp()
        previousStore = InjectedValues[\.hlsPlayerStore]
        InjectedValues[\.hlsPlayerStore] = store
    }

    override func tearDown() async throws {
        subject.dismantle()
        await fulfillment { [store, call] in await store?.player(for: call!) == nil }
        subject = nil
        view = nil
        InjectedValues[\.hlsPlayerStore] = previousStore!
        store = nil
        call = nil
        made.players = []
        try await super.tearDown()
    }

    // MARK: - attach

    func test_attach_hlsCall_showsThePlayer() async {
        call.state.playbackType = .hls(url)

        subject.attach(to: view)
        await fulfilmentInMainActor { self.view.player != nil }

        XCTAssertTrue(view.player === made.players.first)
    }

    func test_attach_webRTCCall_showsNothing() async {
        subject.attach(to: view)
        await wait(for: 0.1)
        let stored = await store.player(for: call)

        XCTAssertNil(view.player)
        XCTAssertNil(stored)
    }

    func test_playbackTypeBecomesHLS_showsThePlayer() async {
        subject.attach(to: view)

        call.state.playbackType = .hls(url)
        await fulfilmentInMainActor { self.view.player != nil }

        XCTAssertTrue(view.player === made.players.first)
    }

    func test_playbackTypeReturnsToWebRTC_removesThePlayer() async {
        call.state.playbackType = .hls(url)
        subject.attach(to: view)
        await fulfilmentInMainActor { self.view.player != nil }

        call.state.playbackType = .webRTC
        await fulfilmentInMainActor { self.view.player == nil }
        let stored = await store.player(for: call)

        XCTAssertNil(stored)
    }

    // MARK: - update(call:)

    func test_updateCall_anotherCall_movesThePlayerToTheNewCall() async {
        call.state.playbackType = .hls(url)
        subject.attach(to: view)
        await fulfilmentInMainActor { self.view.player != nil }
        let other = MockCall()
        other.state.playbackType = .hls(url)

        subject.update(call: other)
        await fulfilmentInMainActor {
            self.view.player === self.made.players.last && self.made.players.count == 2
        }
        let oldPlayer = await store.player(for: call)
        let newPlayer = await store.player(for: other)

        XCTAssertEqual(made.players.count, 2)
        XCTAssertNil(oldPlayer)
        XCTAssertTrue(newPlayer === made.players[1])
    }

    func test_updateCall_anotherCall_stopsFollowingTheOldCall() async {
        subject.attach(to: view)
        let other = MockCall()

        subject.update(call: other)
        call.state.playbackType = .hls(url)
        await wait(for: 0.1)
        let stored = await store.player(for: call)

        XCTAssertNil(view.player)
        XCTAssertNil(stored)
    }

    func test_updateCall_sameCall_keepsThePlayer() async {
        call.state.playbackType = .hls(url)
        subject.attach(to: view)
        await fulfilmentInMainActor { self.view.player != nil }

        subject.update(call: call)

        XCTAssertEqual(made.players.count, 1)
        XCTAssertTrue(view.player === made.players.first)
    }

    func test_updateCall_whileAcquireIsInFlight_showsThePlayerOfTheNewCall() async {
        call.state.playbackType = .hls(url)
        subject.attach(to: view)
        let other = MockCall()
        other.state.playbackType = .hls(url)

        subject.update(call: other)
        await fulfilmentInMainActor {
            self.view.player != nil && self.made.players.count == 2
        }
        let oldPlayer = await store.player(for: call)
        let newPlayer = await store.player(for: other)

        XCTAssertTrue(view.player === made.players[1])
        XCTAssertTrue(newPlayer === made.players[1])
        XCTAssertNil(oldPlayer)
    }

    // MARK: - onPlayerReady

    func test_attach_webRTCCall_doesNotCallOnPlayerReady() async {
        let subject = HLSVideoRenderer.Representable.Coordinator(call: call) { [weak self] in
            self?._readyCount.mutate { $0 += 1 }
        }

        subject.attach(to: view)
        await wait(for: 0.1)

        XCTAssertEqual(readyCount, 0)
        subject.dismantle()
        await fulfillment { [store, call] in await store?.player(for: call!) == nil }
    }

    func test_playbackTypeBecomesHLS_callsOnPlayerReadyOnce() async {
        let subject = HLSVideoRenderer.Representable.Coordinator(call: call) { [weak self] in
            self?._readyCount.mutate { $0 += 1 }
        }
        subject.attach(to: view)

        call.state.playbackType = .hls(url)
        await fulfilmentInMainActor { self.readyCount == 1 }

        XCTAssertEqual(readyCount, 1)
        subject.dismantle()
        await fulfillment { [store, call] in await store?.player(for: call!) == nil }
    }

    // MARK: - dismantle

    func test_dismantle_releasesThePlayerAndEmptiesTheView() async {
        call.state.playbackType = .hls(url)
        subject.attach(to: view)
        await fulfilmentInMainActor { self.view.player != nil }

        subject.dismantle()
        await fulfilmentInMainActor { self.view.player == nil }
        await fulfillment { [store, call] in await store?.player(for: call!) == nil }
    }

    func test_dismantle_whileAcquireIsInFlight_releasesTheClaim() async {
        call.state.playbackType = .hls(url)
        subject.attach(to: view)

        subject.dismantle()
        await wait(for: 0.2)
        let stored = await store.player(for: call)

        XCTAssertNil(stored)
        XCTAssertNil(view.player)
    }

    func test_dismantle_oneOfTwoRenderers_keepsThePlayerForTheOther() async {
        call.state.playbackType = .hls(url)
        let other = HLSVideoRenderer.Representable.Coordinator(call: call)
        other.attach(to: HLSPlayerView())
        subject.attach(to: view)
        await fulfilmentInMainActor { self.view.player != nil }

        subject.dismantle()
        await fulfilmentInMainActor { self.view.player == nil }
        let stored = await store.player(for: call)

        XCTAssertNotNil(stored)
        other.dismantle()
        await fulfillment { [store, call] in await store?.player(for: call!) == nil }
    }
}
