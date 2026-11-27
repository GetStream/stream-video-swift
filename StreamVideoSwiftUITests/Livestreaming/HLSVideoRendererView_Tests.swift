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
final class HLSVideoRendererView_Tests: StreamVideoTestCase, @unchecked Sendable {

    private let url = URL(string: "https://example.com/live.m3u8")!
    private let made = MadePlayers()
    private lazy var mockAppState: MockAppStateAdapter! = .init()
    private lazy var call: MockCall! = makeCall()
    private lazy var view: HLSPlayerView! = .init()
    private lazy var subject: HLSVideoRendererView.Coordinator! = .init(call: call)

    override func setUp() async throws {
        try await super.setUp()
        mockAppState.makeShared()
    }

    override func tearDown() async throws {
        subject.dismantle()
        mockAppState.dismante()
        mockAppState = nil
        subject = nil
        view = nil
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

        XCTAssertNil(view.player)
        XCTAssertTrue(made.players.isEmpty)
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
        await fulfillment { [made] in made.players.first?.pauseCount == 1 }
    }

    func test_playlistURLChanges_showsThePlayerOfTheNewURL() async {
        call.state.playbackType = .hls(url)
        subject.attach(to: view)
        await fulfilmentInMainActor { self.view.player != nil }

        call.state.playbackType = .hls(URL(string: "https://example.com/other.m3u8")!)

        await fulfilmentInMainActor {
            self.made.players.count == 2 && self.view.player === self.made.players[1]
        }
    }

    // MARK: - the host leaves and returns

    func test_backstageBecomesTrue_removesThePlayer() async {
        call.state.playbackType = .hls(url)
        subject.attach(to: view)
        await fulfilmentInMainActor { self.view.player != nil }

        call.state.backstage = true

        XCTAssertNil(view.player)
    }

    func test_backstageBecomesFalse_withTheSameURL_showsANewPlayer() async {
        call.state.playbackType = .hls(url)
        subject.attach(to: view)
        await fulfilmentInMainActor { self.view.player != nil }
        call.state.backstage = true

        call.state.backstage = false

        await fulfilmentInMainActor {
            self.made.players.count == 2 && self.view.player === self.made.players[1]
        }
    }

    func test_hlsBroadcastingStarted_withANewURL_showsANewPlayer() async {
        call.state.playbackType = .hls(url)
        subject.attach(to: view)
        await fulfilmentInMainActor { self.view.player != nil }
        call.state.updateState(from: .typeCallHLSBroadcastingStoppedEvent(
            .init(callCid: "livestream:1", createdAt: Date())
        ))

        call.state.updateState(from: .typeCallHLSBroadcastingStartedEvent(
            .init(
                call: .dummy(),
                callCid: "livestream:1",
                createdAt: Date(),
                hlsPlaylistUrl: "https://example.com/other.m3u8"
            )
        ))

        await fulfilmentInMainActor {
            self.made.players.count == 2 && self.view.player === self.made.players[1]
        }
    }

    // MARK: - update(call:)

    func test_updateCall_anotherCall_movesThePlayerToTheNewCall() async {
        call.state.playbackType = .hls(url)
        subject.attach(to: view)
        await fulfilmentInMainActor { self.view.player != nil }
        let other = makeCall()
        other.state.playbackType = .hls(url)

        subject.update(call: other)
        await fulfilmentInMainActor {
            self.made.players.count == 2 && self.view.player === self.made.players[1]
        }
        let newPlayer = await other.hlsPlayer()

        XCTAssertTrue(newPlayer === made.players[1])
    }

    func test_updateCall_anotherCall_stopsFollowingTheOldCall() async {
        subject.attach(to: view)
        let other = makeCall()

        subject.update(call: other)
        call.state.playbackType = .hls(url)
        await wait(for: 0.1)

        XCTAssertNil(view.player)
        XCTAssertTrue(made.players.isEmpty)
    }

    func test_updateCall_anotherInstanceWithTheSameCId_followsTheNewInstance() async {
        subject.attach(to: view)
        let other = makeCall(callType: call.callType, callId: call.callId)
        other.state.playbackType = .hls(url)

        subject.update(call: other)

        await fulfilmentInMainActor { self.view.player != nil }
        let player = await other.hlsPlayer()
        XCTAssertTrue(view.player === player)
    }

    func test_updateCall_sameCall_keepsThePlayer() async {
        call.state.playbackType = .hls(url)
        subject.attach(to: view)
        await fulfilmentInMainActor { self.view.player != nil }

        subject.update(call: call)

        XCTAssertEqual(made.players.count, 1)
        XCTAssertTrue(view.player === made.players.first)
    }

    func test_updateCall_whileThePlayerRequestIsInFlight_showsThePlayerOfTheNewCall() async {
        call.state.playbackType = .hls(url)
        subject.attach(to: view)
        let other = makeCall()
        other.state.playbackType = .hls(url)

        subject.update(call: other)
        await fulfilmentInMainActor { self.view.player != nil }
        let newPlayer = await other.hlsPlayer()

        XCTAssertNotNil(newPlayer)
        XCTAssertTrue(view.player === newPlayer)
    }

    // MARK: - dismantle

    func test_dismantle_emptiesTheViewAndKeepsThePlayerOfTheCall() async {
        call.state.playbackType = .hls(url)
        subject.attach(to: view)
        await fulfilmentInMainActor { self.view.player != nil }

        subject.dismantle()

        XCTAssertNil(view.player)
        let player = await call.hlsPlayer()
        XCTAssertTrue(player === made.players.first)
        XCTAssertEqual(made.players.first?.pauseCount, 0)
    }

    func test_dismantle_whileThePlayerRequestIsInFlight_keepsTheViewEmpty() async {
        call.state.playbackType = .hls(url)
        subject.attach(to: view)

        subject.dismantle()
        await wait(for: 0.2)

        XCTAssertNil(view.player)
    }

    func test_twoRenderers_ofTheSameCall_shareThePlayerInstance() async {
        call.state.playbackType = .hls(url)
        let otherView = HLSPlayerView()
        let other = HLSVideoRendererView.Coordinator(call: call)
        other.attach(to: otherView)
        subject.attach(to: view)
        await fulfilmentInMainActor { self.view.player != nil && otherView.player != nil }

        XCTAssertTrue(view.player === otherView.player)
        XCTAssertEqual(made.players.count, 1)
        subject.dismantle()
        XCTAssertNil(view.player)
        XCTAssertNotNil(otherView.player)
        other.dismantle()
    }

    // MARK: - Private Helpers

    private func makeCall(
        callType: String = .default,
        callId: String = .unique
    ) -> MockCall {
        let adapter = HLSStateAdapter { [made] _ in
            let player = MockHLSPlayer()
            made.players.append(player)
            return player
        }
        return MockCall(
            .dummy(
                callType: callType,
                callId: callId,
                callController: MockCallController(hlsStateAdapter: adapter)
            )
        )
    }
}
