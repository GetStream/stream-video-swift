//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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

    private lazy var targetSize: CGSize = .init(width: 400, height: 200)

    func test_content_inactive() {
        AssertSnapshot(
            makeSubject(.inactive),
            variants: snapshotVariants,
            size: targetSize
        )
    }

    func test_content_participant() {
        AssertSnapshot(
            makeSubject(.participant(MockCall(.dummy()), .dummy(name: "Get Stream"), nil)),
            variants: snapshotVariants,
            size: targetSize
        )
    }

    func test_content_screenSharing() {
        AssertSnapshot(
            makeSubject(
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

    func test_content_reconnecting() {
        AssertSnapshot(
            makeSubject(.reconnecting),
            variants: snapshotVariants,
            size: targetSize
        )
    }

    // MARK: - Private Helpers

    private func makeSubject(_ content: PictureInPictureContent) -> some View {
        let store = PictureInPictureStore()
        store.dispatch(.setContent(content))
        return PictureInPictureContentView(store: store)
            .frame(width: targetSize.width, height: targetSize.height)
    }
}
