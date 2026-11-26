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

    @MainActor
    func test_hlsCall_playerLayerOfTheCall_controllerShowsThePlayerLayer() async {
        let call = makeHLSCall()
        let configured = await makeConfiguredSubject(callFirst: true, call: call)
        let layer = AVPlayerLayer()

        configured.store.dispatch(.setPlayerLayer(layer, cId: call.cId))

        await fulfilmentInMainActor {
            configured.factory.latestContentSource?.playerLayer === layer
        }
        withExtendedLifetime(configured.subject) {}
    }

    @MainActor
    func test_hlsCall_withoutPlayerLayer_controllerShowsTheVideoCall() async {
        let configured = await makeConfiguredSubject(callFirst: true, call: makeHLSCall())

        let source = configured.factory.latestContentSource
        XCTAssertNotNil(source?.activeVideoCallSourceView)
        XCTAssertNil(source?.playerLayer)
        withExtendedLifetime(configured.subject) {}
    }

    @MainActor
    func test_hlsCall_playerLayerOfAnotherCall_controllerShowsTheVideoCall() async {
        let configured = await makeConfiguredSubject(callFirst: true, call: makeHLSCall())

        await assertShowsVideoCall(configured, afterRegistering: "other:call")
    }

    @MainActor
    func test_webRTCCall_playerLayerRegistered_controllerShowsTheVideoCall() async {
        let call = MockCall()
        let configured = await makeConfiguredSubject(callFirst: true, call: call)

        await assertShowsVideoCall(configured, afterRegistering: call.cId)
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

    /// Registers a layer, then sends a newer source view. The controller
    /// handles the updates in order, so the source of the new view is the
    /// outcome of the layer registration.
    @MainActor
    private func assertShowsVideoCall(
        _ configured: (
            subject: PictureInPictureController?,
            store: PictureInPictureStore,
            factory: Factory
        ),
        afterRegistering cId: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let marker = UIView()
        configured.store.dispatch(.setPlayerLayer(AVPlayerLayer(), cId: cId))
        configured.store.dispatch(.setSourceView(marker))

        await fulfilmentInMainActor(filePath: file, line: line) {
            configured.factory.latestContentSource?.activeVideoCallSourceView === marker
        }

        XCTAssertNil(configured.factory.latestContentSource?.playerLayer, file: file, line: line)
        withExtendedLifetime(configured.subject) {}
    }

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

    /// The source of the last controller. A simulator can't create a system
    /// controller, so it falls back to the last source the factory received.
    var latestContentSource: AVPictureInPictureController.ContentSource? {
        controllers.last?.contentSource ?? contentSources.last
    }

    func make(
        contentSource: AVPictureInPictureController.ContentSource
    ) -> AVPictureInPictureController {
        contentSources.append(contentSource)
        let controller = AVPictureInPictureController(contentSource: contentSource)
        controllers.append(controller)
        return controller
    }
}
