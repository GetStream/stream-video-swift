//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideoSwiftUI
import XCTest

final class StreamPictureInPictureVideoRenderer_Tests: XCTestCase, @unchecked Sendable {

    @MainActor
    func test_didUpdateTrackSize_windowSizePolicyWasUpdated() async {
        let spyPolicy = StreamTestSpyPictureInPictureWindowSizePolicy()
        let subject = StreamPictureInPictureVideoRenderer(windowSizePolicy: spyPolicy)
        let targetSize = CGSize(width: 100, height: 150)
        subject.frame = .init(origin: .zero, size: .init(width: 300, height: 400))
        subject.layoutSubviews()

        subject.setSize(targetSize)

        await fulfilmentInMainActor {
            targetSize == spyPolicy.trackSize
        }
    }
}

// MARK: - Spies

private final class StreamTestSpyPictureInPictureWindowSizePolicy: PictureInPictureWindowSizePolicy {
    var trackSize: CGSize = .zero
    var controller: (any StreamVideoSwiftUI.StreamAVPictureInPictureViewControlling)?
}
