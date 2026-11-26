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

    private var previousAdapter: StreamPictureInPictureAdapter?
    private lazy var call: MockCall! = .init()
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
        call = nil
        mockAppStateAdapter.dismante()
        mockAppStateAdapter = nil
        if let previousAdapter {
            InjectedValues[\.pictureInPictureAdapter] = previousAdapter
        }
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

    // MARK: - Picture in Picture

    func test_appEntersBackground_pictureInPictureActive_keepsThePlayerAttached() async {
        let store = await injectPictureInPictureStore()
        subject.player = player
        mockAppStateAdapter.stubbedState = .background

        activatePictureInPicture(of: subject.playerLayer, in: store)

        await fulfilmentInMainActor { self.layerPlayer === self.player }
    }

    func test_pictureInPictureStops_appInBackground_detachesThePlayer() async {
        let store = await injectPictureInPictureStore()
        subject.player = player
        mockAppStateAdapter.stubbedState = .background
        activatePictureInPicture(of: subject.playerLayer, in: store)
        await fulfilmentInMainActor { self.layerPlayer === self.player }

        store.dispatch(.setActive(false))

        await fulfilmentInMainActor { self.layerPlayer == nil }
    }

    func test_appEntersBackground_pictureInPictureInactive_detachesThePlayer() async {
        _ = await injectPictureInPictureStore()
        subject.player = player

        mockAppStateAdapter.stubbedState = .background

        XCTAssertNil(layerPlayer)
    }

    func test_appEntersBackground_pictureInPictureShowsAnotherLayer_detachesThePlayer() async {
        let store = await injectPictureInPictureStore()
        subject.player = player

        await activatePictureInPictureAndWaitForTheView(
            of: HLSPlayerView().playerLayer,
            in: store
        )
        mockAppStateAdapter.stubbedState = .background

        XCTAssertNil(layerPlayer)
    }

    func test_appEntersBackground_layerRegisteredForAnotherCall_detachesThePlayer() async {
        let store = await injectPictureInPictureStore()
        subject.player = player

        await activatePictureInPictureAndWaitForTheView(
            of: subject.playerLayer,
            cId: "other:call",
            in: store
        )
        mockAppStateAdapter.stubbedState = .background

        XCTAssertNil(layerPlayer)
    }

    // MARK: - Private Helpers

    private func activatePictureInPicture(
        of layer: AVPlayerLayer,
        cId: String? = nil,
        in store: PictureInPictureStore
    ) {
        store.dispatch(.setCall(call))
        store.dispatch(.setPlayerLayer(layer, cId: cId ?? call.cId))
        store.dispatch(.setActive(true))
    }

    /// The view has no state to observe, so this subscribes after the view.
    /// The store sends a change to the subscribers in order, and each one
    /// hops to the main queue. This delivery then comes after the view's.
    private func activatePictureInPictureAndWaitForTheView(
        of layer: AVPlayerLayer,
        cId: String? = nil,
        in store: PictureInPictureStore
    ) async {
        let delivered = expectation(description: "The state reached the view.")
        let observer = store.publisher(for: \.isActive)
            .filter { $0 }
            .sink { _ in delivered.fulfill() }
        activatePictureInPicture(of: layer, cId: cId, in: store)
        await fulfillment(of: [delivered], timeout: defaultTimeout)
        observer.cancel()
    }

    /// Replaces the shared adapter with a fresh one. Teardown restores it.
    private func injectPictureInPictureStore() async -> PictureInPictureStore {
        previousAdapter = previousAdapter ?? InjectedValues[\.pictureInPictureAdapter]
        let adapter = StreamPictureInPictureAdapter()
        InjectedValues[\.pictureInPictureAdapter] = adapter
        await fulfilmentInMainActor { adapter.store != nil }
        return adapter.store!
    }
}
