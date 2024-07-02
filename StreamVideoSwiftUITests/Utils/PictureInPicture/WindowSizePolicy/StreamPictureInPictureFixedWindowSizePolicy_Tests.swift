//
//  StreamPictureInPictureFixedWindowSizePolicy_Tests.swift
//  StreamVideoSwiftUITests
//
//  Created by Ilias Pavlidakis on 15/7/24.
//

import Foundation
import XCTest
@testable import StreamVideoSwiftUI

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
