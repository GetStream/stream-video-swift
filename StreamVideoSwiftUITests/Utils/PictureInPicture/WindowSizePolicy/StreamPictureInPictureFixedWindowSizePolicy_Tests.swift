//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideoSwiftUI
import XCTest

final class StreamPictureInPictureFixedWindowSizePolicy_Tests: XCTestCase {

    private lazy var targetSize: CGSize! = .init(width: 100, height: 280)
    private lazy var subject: StreamPictureInPictureFixedWindowSizePolicy! = .init(targetSize)

    override func tearDown() {
        targetSize = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - didSetController

    func test_didSetController_setsPreferredContentSizeOnController() {
        let controller = MockStreamAVPictureInPictureViewControlling()
        subject.controller = controller

        XCTAssertEqual(controller.preferredContentSize, targetSize)
    }
}
