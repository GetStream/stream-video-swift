//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
@preconcurrency import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import StreamWebRTC
import SwiftUI
import XCTest

@MainActor
final class PictureInPictureContentViewTests: StreamVideoUITestCase, @unchecked Sendable {

    private var mockStreamVideo: MockStreamVideo! = .init()
    private lazy var targetSize: CGSize = .init(width: 400, height: 200)

    override func tearDown() async throws {
        mockStreamVideo = nil
        try await super.tearDown()
    }

    func test_content_inactive() async {
        AssertSnapshot(
            await makeSubject(.inactive),
            variants: snapshotVariants,
            size: targetSize
        )
    }

    func test_content_participant() async {
        AssertSnapshot(
            await makeSubject(.participant(MockCall(.dummy()), .dummy(name: "Get Stream"), nil)),
            variants: snapshotVariants,
            size: targetSize
        )
    }

    func test_content_screenSharing() async {
        AssertSnapshot(
            await makeSubject(
                .screenSharing(
                    MockCall(.dummy()),
                    .dummy(name: "Get Stream"),
                    RTCMediaStreamTrack.dummy(kind: .video, peerConnectionFactory: .mock()) as! RTCVideoTrack
                )
            ),
            variants: snapshotVariants,
            size: targetSize
        )
    }

    func test_content_reconnecting() async {
        AssertSnapshot(
            await makeSubject(.reconnecting),
            variants: snapshotVariants,
            size: targetSize
        )
    }

    // MARK: - Private Helpers

    private func makeSubject(_ content: PictureInPictureContent) async -> some View {
        let store = PictureInPictureStore()
        store.dispatch(.setContent(content))
        await fulfilmentInMainActor {
            store.state.content == content
        }
        return PictureInPictureContentView(store: store)
            .frame(width: targetSize.width, height: targetSize.height)
    }
}
