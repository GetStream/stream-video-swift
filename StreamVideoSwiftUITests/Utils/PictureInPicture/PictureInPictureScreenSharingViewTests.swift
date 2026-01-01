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
final class PictureInPictureScreenSharingViewTests: StreamVideoUITestCase, @unchecked Sendable {

    private lazy var targetSize: CGSize = .init(width: 400, height: 200)

    func test_content() {
        AssertSnapshot(
            makeSubject(),
            variants: snapshotVariants,
            size: targetSize
        )
    }

    // MARK: - Private Helpers

    private func makeSubject() -> some View {
        PictureInPictureScreenSharingView(
            store: .init(),
            participant: .dummy(name: "Get Stream"),
            track: RTCMediaStreamTrack.dummy(kind: .video, peerConnectionFactory: .mock()) as! RTCVideoTrack
        )
        .frame(width: targetSize.width, height: targetSize.height)
    }
}
