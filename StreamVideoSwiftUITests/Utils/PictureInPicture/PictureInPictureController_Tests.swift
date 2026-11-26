//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import UIKit
import XCTest

@available(iOS 15.0, *)
final class PictureInPictureControllerTests: XCTestCase, @unchecked Sendable {

    private var mockStreamVideo: MockStreamVideo! = .init()

    override func tearDown() async throws {
        mockStreamVideo = nil
        try await super.tearDown()
    }

    @MainActor
    func test_sourceViewUpdatedBeforeCall_callUpdated_controllerWasConfigured() async {
        let configured = await makeConfiguredSubject(callFirst: false)

        XCTAssertNotNil(configured.subject)
    }

    @MainActor
    func test_callUpdatedBeforeSourceView_sourceViewUpdated_controllerWasConfigured() async {
        let configured = await makeConfiguredSubject(callFirst: true)

        XCTAssertNotNil(configured.subject)
    }

    @MainActor
    func test_callCleared_callRestored_controllerWasReconfigured() async {
        let configured = await makeConfiguredSubject(callFirst: true)

        configured.store.dispatch(.setCall(nil))
        await fulfilmentInMainActor { configured.store.state.call == nil }
        configured.store.dispatch(.setCall(MockCall()))
        await fulfilmentInMainActor { configured.store.state.call != nil }

        await assertControllerWasConfigured(configured.factory, count: 2)
        XCTAssertNotNil(configured.subject)
    }

    @MainActor
    func test_sourceViewCleared_sourceViewRestored_controllerWasReconfigured() async {
        let configured = await makeConfiguredSubject(callFirst: true)

        configured.store.dispatch(.setSourceView(nil))
        await fulfilmentInMainActor { configured.store.state.sourceView == nil }
        configured.store.dispatch(.setSourceView(UIView()))
        await fulfilmentInMainActor { configured.store.state.sourceView != nil }

        await assertControllerWasConfigured(configured.factory, count: 2)
        XCTAssertNotNil(configured.subject)
    }

    // MARK: - Content source

    // A simulator can't create a system controller, so these tests read the
    // content source the factory receives.

    @MainActor
    func test_hlsCall_playerLayerRegistered_controllerShowsThePlayerLayer() async {
        let configured = await makeConfiguredSubject(callFirst: true, call: makeHLSCall())
        let layer = AVPlayerLayer()

        configured.store.dispatch(.setPlayerLayer(layer))

        await fulfilmentInMainActor {
            configured.factory.contentSources.last?.playerLayer === layer
        }
        withExtendedLifetime(configured.subject) {}
    }

    @MainActor
    func test_hlsCall_withoutPlayerLayer_controllerShowsTheVideoCall() async {
        let configured = await makeConfiguredSubject(callFirst: true, call: makeHLSCall())

        let source = configured.factory.contentSources.last
        XCTAssertNotNil(source?.activeVideoCallSourceView)
        XCTAssertNil(source?.playerLayer)
        withExtendedLifetime(configured.subject) {}
    }

    @MainActor
    func test_webRTCCall_playerLayerRegistered_controllerShowsTheVideoCall() async {
        let configured = await makeConfiguredSubject(callFirst: true)

        configured.store.dispatch(.setPlayerLayer(AVPlayerLayer()))
        await fulfilmentInMainActor { configured.store.state.playerLayer != nil }
        await wait(for: 0.1)

        let source = configured.factory.contentSources.last
        XCTAssertNotNil(source?.activeVideoCallSourceView)
        XCTAssertNil(source?.playerLayer)
        withExtendedLifetime(configured.subject) {}
    }

    @MainActor
    func test_pictureInPictureUnsupported_initializationReturnsNil() {
        let subject = PictureInPictureController(
            store: .init(),
            isPictureInPictureSupported: false
        )

        XCTAssertNil(subject)
    }

    // MARK: - Private

    @MainActor
    private func makeHLSCall() -> MockCall {
        let call = MockCall()
        call.state.playbackType = .hls(URL(string: "https://example.com/live.m3u8")!)
        return call
    }

    @MainActor
    private func makeConfiguredSubject(
        callFirst: Bool,
        call: Call = MockCall()
    ) async -> (
        subject: PictureInPictureController?,
        store: PictureInPictureStore,
        factory: Factory
    ) {
        let store = PictureInPictureStore()
        let factory = Factory()
        let subject = PictureInPictureController(
            store: store,
            isPictureInPictureSupported: true,
            makePictureInPictureController: factory.make
        )
        if callFirst {
            store.dispatch(.setCall(call))
            await fulfilmentInMainActor { store.state.call != nil }
            store.dispatch(.setSourceView(UIView()))
            await fulfilmentInMainActor { store.state.sourceView != nil }
        } else {
            store.dispatch(.setSourceView(UIView()))
            await fulfilmentInMainActor { store.state.sourceView != nil }
            store.dispatch(.setCall(call))
            await fulfilmentInMainActor { store.state.call != nil }
        }
        await assertControllerWasConfigured(factory)
        return (subject, store, factory)
    }

    @MainActor
    private func assertControllerWasConfigured(
        _ factory: Factory,
        count: Int = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        await fulfilmentInMainActor(filePath: file, line: line) {
            factory.controllers.count == count
        }
        XCTAssertEqual(factory.controllers.count, count, file: file, line: line)
        XCTAssertEqual(factory.contentSources.count, count, file: file, line: line)
    }
}

@available(iOS 15.0, *)
@MainActor
private final class Factory {

    private(set) var contentSources: [AVPictureInPictureController.ContentSource] = []
    private(set) var controllers: [AVPictureInPictureController] = []

    func make(
        contentSource: AVPictureInPictureController.ContentSource
    ) -> AVPictureInPictureController {
        contentSources.append(contentSource)
        let controller = AVPictureInPictureController(contentSource: contentSource)
        controllers.append(controller)
        return controller
    }
}
