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
        let player = HLSSpyPlayer()
        made.players.append(player)
        return player
    }

    private lazy var view: HLSPlayerView! = .init()
    private lazy var subject: HLSVideoRenderer.Coordinator! = .init(call: call, store: store)

    override func tearDown() async throws {
        subject.dismantle()
        await subject.finishPlaybackUpdate()
        subject = nil
        view = nil
        store = nil
        call = nil
        made.players = []
        try await super.tearDown()
    }

    // MARK: - videoGravity

    func test_videoGravity_scaleAspectFit_resizesAspect() {
        XCTAssertEqual(HLSVideoRenderer.videoGravity(for: .scaleAspectFit), .resizeAspect)
    }

    func test_videoGravity_scaleAspectFill_resizesAspectFill() {
        XCTAssertEqual(HLSVideoRenderer.videoGravity(for: .scaleAspectFill), .resizeAspectFill)
    }

    func test_videoGravity_scaleToFill_resizes() {
        XCTAssertEqual(HLSVideoRenderer.videoGravity(for: .scaleToFill), .resize)
    }

    func test_videoGravity_otherModes_resizeAspect() {
        XCTAssertEqual(HLSVideoRenderer.videoGravity(for: .center), .resizeAspect)
    }

    // MARK: - init

    func test_init_usesTheInjectedStore() {
        let injected = HLSPlayerStore { _ in HLSSpyPlayer() }
        let previous = InjectedValues[\.hlsPlayerStore]
        InjectedValues[\.hlsPlayerStore] = injected
        defer { InjectedValues[\.hlsPlayerStore] = previous }

        let renderer = HLSVideoRenderer(call: call)

        XCTAssertTrue(renderer.store === injected)
    }

    // MARK: - attach

    func test_attach_hlsCall_showsThePlayer() async {
        call.state.playbackType = .hls(url)

        subject.attach(to: view)
        await subject.finishPlaybackUpdate()

        XCTAssertTrue(view.player === made.players.first)
    }

    func test_attach_webRTCCall_showsNothing() async {
        subject.attach(to: view)
        await subject.finishPlaybackUpdate()
        let count = await store.activePlayerCount

        XCTAssertNil(view.player)
        XCTAssertEqual(count, 0)
    }

    func test_playbackTypeBecomesHLS_showsThePlayer() async {
        subject.attach(to: view)
        await subject.finishPlaybackUpdate()

        call.state.playbackType = .hls(url)
        await subject.finishPlaybackUpdate()

        XCTAssertTrue(view.player === made.players.first)
    }

    func test_playbackTypeReturnsToWebRTC_removesThePlayer() async {
        call.state.playbackType = .hls(url)
        subject.attach(to: view)
        await subject.finishPlaybackUpdate()

        call.state.playbackType = .webRTC
        await subject.finishPlaybackUpdate()
        let count = await store.activePlayerCount

        XCTAssertNil(view.player)
        XCTAssertEqual(count, 0)
    }

    // MARK: - update(call:)

    func test_updateCall_anotherCall_movesThePlayerToTheNewCall() async {
        call.state.playbackType = .hls(url)
        subject.attach(to: view)
        await subject.finishPlaybackUpdate()
        let other = MockCall()
        other.state.playbackType = .hls(url)

        subject.update(call: other)
        await subject.finishPlaybackUpdate()
        let oldPlayer = await store.player(for: call)
        let newPlayer = await store.player(for: other)

        XCTAssertEqual(made.players.count, 2)
        XCTAssertTrue(view.player === made.players[1])
        XCTAssertNil(oldPlayer)
        XCTAssertTrue(newPlayer === made.players[1])
    }

    func test_updateCall_anotherCall_stopsFollowingTheOldCall() async {
        subject.attach(to: view)
        await subject.finishPlaybackUpdate()
        let other = MockCall()

        subject.update(call: other)
        await subject.finishPlaybackUpdate()
        call.state.playbackType = .hls(url)
        await subject.finishPlaybackUpdate()
        let count = await store.activePlayerCount

        XCTAssertNil(view.player)
        XCTAssertEqual(count, 0)
    }

    func test_updateCall_sameCall_keepsThePlayer() async {
        call.state.playbackType = .hls(url)
        subject.attach(to: view)
        await subject.finishPlaybackUpdate()

        subject.update(call: call)
        await subject.finishPlaybackUpdate()

        XCTAssertEqual(made.players.count, 1)
        XCTAssertTrue(view.player === made.players.first)
    }

    // MARK: - dismantle

    func test_dismantle_releasesThePlayerAndEmptiesTheView() async {
        call.state.playbackType = .hls(url)
        subject.attach(to: view)
        await subject.finishPlaybackUpdate()

        subject.dismantle()
        await subject.finishPlaybackUpdate()
        let count = await store.activePlayerCount

        XCTAssertNil(view.player)
        XCTAssertEqual(count, 0)
    }

    func test_dismantle_oneOfTwoRenderers_keepsThePlayerForTheOther() async {
        call.state.playbackType = .hls(url)
        let other = HLSVideoRenderer.Coordinator(call: call, store: store)
        other.attach(to: HLSPlayerView())
        await other.finishPlaybackUpdate()
        subject.attach(to: view)
        await subject.finishPlaybackUpdate()

        subject.dismantle()
        await subject.finishPlaybackUpdate()
        let count = await store.activePlayerCount

        XCTAssertEqual(count, 1)
        other.dismantle()
        await other.finishPlaybackUpdate()
    }
}

private final class MadePlayers: @unchecked Sendable {
    var players: [HLSSpyPlayer] = []
}
