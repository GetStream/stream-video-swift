//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import UIKit
import XCTest

@available(iOS 15.0, *)
final class StreamPictureInPictureAdapterTests: XCTestCase, @unchecked Sendable {

    private var mockStreamVideo: MockStreamVideo! = .init()
    private lazy var subject: StreamPictureInPictureAdapter! = .init()

    override func tearDown() async throws {
        mockStreamVideo = nil
        subject = nil
        try await super.tearDown()
    }

    // MARK: - Call updated

    @MainActor
    func test_callUpdated_storeWasUpdated() async {
        let call = MockCall(.dummy())
        _ = subject
        await wait(for: 0.5)

        subject.call = call

        await fulfilmentInMainActor { self.subject.store?.state.call?.cId == call.cId }
    }

    // MARK: - Player layer

    @MainActor
    func test_setPlayerLayer_beforeTheStoreExists_reachesTheStore() async {
        let layer = AVPlayerLayer()

        // The store is created a moment after the adapter.
        subject.setPlayerLayer(layer, cId: "call-1")

        await fulfilmentInMainActor { self.subject.store?.state.playerLayer === layer }
        XCTAssertEqual(subject.store?.state.playerLayerCallId, "call-1")
    }

    @MainActor
    func test_removePlayerLayer_beforeTheStoreExists_keepsTheStoreEmpty() async {
        let layer = AVPlayerLayer()
        subject.setPlayerLayer(layer, cId: "call-1")

        subject.removePlayerLayer(layer)

        await fulfilmentInMainActor { self.subject.store != nil }
        await wait(for: 0.2)
        XCTAssertNil(subject.store?.state.playerLayer)
    }

    @MainActor
    func test_setPlayerLayer_afterTheStoreExists_reachesTheStore() async {
        let layer = AVPlayerLayer()
        await fulfilmentInMainActor { self.subject.store != nil }

        subject.setPlayerLayer(layer, cId: "call-1")

        await fulfilmentInMainActor { self.subject.store?.state.playerLayer === layer }
    }

    // MARK: - SourceView updated

    @MainActor
    func test_sourceViewUpdated_storeWasUpdated() async {
        let view = UIView()
        _ = subject
        await wait(for: 0.5)

        subject.sourceView = view

        await fulfilmentInMainActor { self.subject.store?.state.sourceView === view }
    }

    // MARK: - SourceView coordinator lifecycle

    @MainActor
    func test_sourceViewCoordinatorActivated_viewMovesToWindow_storeWasUpdated() async {
        let previousPictureInPictureAdapter = InjectedValues[\.pictureInPictureAdapter]
        InjectedValues[\.pictureInPictureAdapter] = subject
        defer { InjectedValues[\.pictureInPictureAdapter] = previousPictureInPictureAdapter }

        await fulfilmentInMainActor { self.subject.store != nil }
        let coordinator = PictureInPictureSourceView.Coordinator()

        coordinator.update(isActive: true)
        coordinator.view.willMove(toWindow: UIWindow())

        await fulfilmentInMainActor {
            self.subject.store?.state.sourceView === coordinator.view
        }
    }

    @MainActor
    func test_sourceViewCoordinatorDeactivated_storeSourceViewCleared() async {
        let previousPictureInPictureAdapter = InjectedValues[\.pictureInPictureAdapter]
        InjectedValues[\.pictureInPictureAdapter] = subject
        defer { InjectedValues[\.pictureInPictureAdapter] = previousPictureInPictureAdapter }

        await fulfilmentInMainActor { self.subject.store != nil }
        let coordinator = PictureInPictureSourceView.Coordinator()

        coordinator.update(isActive: true)
        coordinator.view.willMove(toWindow: UIWindow())
        await fulfilmentInMainActor {
            self.subject.store?.state.sourceView === coordinator.view
        }

        coordinator.update(isActive: false)

        await fulfilmentInMainActor { self.subject.store?.state.sourceView == nil }
    }

    // MARK: - ViewFactory updated

    @MainActor
    func test_setViewFactory_storeWasUpdated() async {
        final class CustomViewFactory: ViewFactory {}
        _ = subject
        await fulfillment { self.subject.store != nil }
        let viewFactory = CustomViewFactory()

        subject.setViewFactory(viewFactory)

        await fulfillment { self.subject.store?.state.viewFactory.source === viewFactory }
    }
}
