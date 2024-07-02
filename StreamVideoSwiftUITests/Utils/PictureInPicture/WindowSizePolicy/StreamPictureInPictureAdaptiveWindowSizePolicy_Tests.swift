//
//  StreamPictureInPictureAdaptiveWindowSizePolicy_Tests.swift
//  StreamVideoSwiftUITests
//
//  Created by Ilias Pavlidakis on 15/7/24.
//

import Foundation
import XCTest
@testable import StreamVideoSwiftUI

final class StreamPictureInPictureAdaptiveWindowSizePolicy_Tests: XCTestCase {

    private lazy var targetSize: CGSize! = .init(width: 100, height: 280)
    private lazy var subject: StreamPictureInPictureAdaptiveWindowSizePolicy! = .init()

    override func tearDown() {
        targetSize = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - didSetTrackSize

    func test_didSetTrackSize_setsPreferredContentSizeOnController() {
        let controller = MockStreamAVPictureInPictureViewControlling()
        subject.controller = controller

        subject.trackSize = targetSize

        XCTAssertEqual(controller.preferredContentSize, targetSize)
    }
}

