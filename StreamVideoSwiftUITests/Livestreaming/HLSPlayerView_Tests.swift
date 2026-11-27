//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class HLSPlayerView_Tests: StreamVideoTestCase, @unchecked Sendable {

    private lazy var mockAppStateAdapter: MockAppStateAdapter! = .init()
    private lazy var player: MockHLSPlayer! = .init()
    private lazy var subject: HLSPlayerView! = {
        mockAppStateAdapter.makeShared()
        return HLSPlayerView()
    }()

    private var layerPlayer: AVPlayer? { (subject.layer as? AVPlayerLayer)?.player }

    override func tearDown() async throws {
        subject = nil
        player = nil
        mockAppStateAdapter.dismante()
        mockAppStateAdapter = nil
        try await super.tearDown()
    }

    // MARK: - player

    func test_player_appInForeground_attachesThePlayerToTheLayer() {
        subject.player = player

        XCTAssertTrue(layerPlayer === player)
        XCTAssertTrue(subject.player === player)
    }

    // MARK: - application state

    func test_appEntersBackground_detachesThePlayerButKeepsTheReference() {
        subject.player = player

        mockAppStateAdapter.stubbedState = .background

        XCTAssertNil(layerPlayer)
        XCTAssertTrue(subject.player === player)
    }

    func test_appReturnsToForeground_attachesThePlayerAgain() {
        subject.player = player
        mockAppStateAdapter.stubbedState = .background

        mockAppStateAdapter.stubbedState = .foreground

        XCTAssertTrue(layerPlayer === player)
    }

    func test_playerSetInBackground_attachesOnlyWhenTheAppReturnsToForeground() {
        mockAppStateAdapter.stubbedState = .background

        subject.player = player
        XCTAssertNil(layerPlayer)

        mockAppStateAdapter.stubbedState = .foreground
        XCTAssertTrue(layerPlayer === player)
    }

    func test_playerRemovedInBackground_staysDetachedInForeground() {
        subject.player = player
        mockAppStateAdapter.stubbedState = .background

        subject.player = nil
        mockAppStateAdapter.stubbedState = .foreground

        XCTAssertNil(layerPlayer)
    }
}
