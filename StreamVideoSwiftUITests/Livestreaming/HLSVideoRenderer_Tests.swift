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
    private var madePlayers: [HLSSpyPlayer] = []
    private lazy var call: MockCall! = .init()
    private lazy var store: HLSPlayerStore! = .init { [unowned self] _ in
        let player = HLSSpyPlayer()
        madePlayers.append(player)
        return player
    }

    private lazy var view: HLSPlayerView! = .init()
    private lazy var subject: HLSVideoRenderer.Coordinator! = .init(call: call, store: store)

    override func tearDown() async throws {
        subject.dismantle()
        subject = nil
        view = nil
        store = nil
        call = nil
        madePlayers = []
        try await super.tearDown()
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

    func test_attach_hlsCall_showsThePlayer() {
        call.state.playbackType = .hls(url)

        subject.attach(to: view)

        XCTAssertTrue(view.player === madePlayers.first)
    }

    func test_attach_webRTCCall_showsNothing() {
        subject.attach(to: view)

        XCTAssertNil(view.player)
        XCTAssertEqual(store.activePlayerCount, 0)
    }

    func test_playbackTypeBecomesHLS_showsThePlayer() {
        subject.attach(to: view)

        call.state.playbackType = .hls(url)

        XCTAssertTrue(view.player === madePlayers.first)
    }

    func test_playbackTypeReturnsToWebRTC_removesThePlayer() {
        call.state.playbackType = .hls(url)
        subject.attach(to: view)

        call.state.playbackType = .webRTC

        XCTAssertNil(view.player)
        XCTAssertEqual(store.activePlayerCount, 0)
    }

    // MARK: - update(call:)

    func test_updateCall_anotherCall_movesThePlayerToTheNewCall() {
        call.state.playbackType = .hls(url)
        subject.attach(to: view)
        let other = MockCall()
        other.state.playbackType = .hls(url)

        subject.update(call: other)

        XCTAssertEqual(madePlayers.count, 2)
        XCTAssertTrue(view.player === madePlayers[1])
        XCTAssertNil(store.player(for: call))
        XCTAssertTrue(store.player(for: other) === madePlayers[1])
    }

    func test_updateCall_anotherCall_stopsFollowingTheOldCall() {
        subject.attach(to: view)
        let other = MockCall()

        subject.update(call: other)
        call.state.playbackType = .hls(url)

        XCTAssertNil(view.player)
        XCTAssertEqual(store.activePlayerCount, 0)
    }

    func test_updateCall_sameCall_keepsThePlayer() {
        call.state.playbackType = .hls(url)
        subject.attach(to: view)

        subject.update(call: call)

        XCTAssertEqual(madePlayers.count, 1)
        XCTAssertTrue(view.player === madePlayers.first)
    }

    // MARK: - onPlayerReady

    func test_attach_webRTCCall_doesNotCallOnPlayerReady() {
        var readyCount = 0
        let subject = HLSVideoRenderer.Coordinator(call: call, store: store) {
            readyCount += 1
        }

        subject.attach(to: view)

        XCTAssertEqual(readyCount, 0)
        subject.dismantle()
    }

    func test_playbackTypeBecomesHLS_callsOnPlayerReadyOnce() {
        var readyCount = 0
        let subject = HLSVideoRenderer.Coordinator(call: call, store: store) {
            readyCount += 1
        }
        subject.attach(to: view)

        call.state.playbackType = .hls(url)

        XCTAssertEqual(readyCount, 1)
        subject.dismantle()
    }

    // MARK: - dismantle

    func test_dismantle_releasesThePlayerAndEmptiesTheView() {
        call.state.playbackType = .hls(url)
        subject.attach(to: view)

        subject.dismantle()

        XCTAssertNil(view.player)
        XCTAssertEqual(store.activePlayerCount, 0)
    }

    func test_dismantle_oneOfTwoRenderers_keepsThePlayerForTheOther() {
        call.state.playbackType = .hls(url)
        let other = HLSVideoRenderer.Coordinator(call: call, store: store)
        other.attach(to: HLSPlayerView())
        subject.attach(to: view)

        subject.dismantle()

        XCTAssertEqual(store.activePlayerCount, 1)
        other.dismantle()
    }
}
