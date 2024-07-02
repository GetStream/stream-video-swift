//
//  StreamPictureInPictureVideoRendererTests.swift
//  StreamVideoSwiftUITests
//
//  Created by Ilias Pavlidakis on 15/7/24.
//

import Foundation
import XCTest
@testable import StreamVideoSwiftUI

final class StreamPictureInPictureVideoRenderer_Tests: XCTestCase {

    func test_didUpdateTrackSize_windowSizePolicyWasUpdated() {
        let spyPolicy = StreamTestSpyPictureInPictureWindowSizePolicy()
        let subject = StreamPictureInPictureVideoRenderer(windowSizePolicy: spyPolicy)
        let targetSize = CGSize(width: 100, height: 150)
        subject.frame = .init(origin: .zero, size: .init(width: 300, height: 400))
        subject.layoutSubviews()

        subject.setSize(targetSize)

        XCTAssertEqual(targetSize, spyPolicy.trackSize)
    }
}

// MARK: - Spies

private final class StreamTestSpyPictureInPictureWindowSizePolicy: PictureInPictureWindowSizePolicy {
    var trackSize: CGSize = .zero
    var controller: (any StreamVideoSwiftUI.StreamAVPictureInPictureViewControlling)?
}
