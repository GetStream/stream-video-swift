//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
@testable import StreamVideoSwiftUI
import StreamSwiftTestHelpers
import SnapshotTesting
import XCTest
import Foundation

@MainActor
final class SpotlightSpeakerView_Tests: StreamVideoUITestCase {

    private lazy var subject: SpotlightSpeakerView! = SpotlightSpeakerView(
        viewFactory: TestViewFactory(),
        participant: .dummy(
            id: "test-user-1",
            name: "test-user-1",
            profileImageURL: Bundle(for: type(of: self)).url(forResource: "mock-profile-image", withExtension: "jpg")!
        ),
        viewIdSuffix: "spotlight",
        call: nil,
        availableFrame: .init(origin: .zero, size: .init(width: 200, height: 300))
    )

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - viewId

    func test_viewId_returnsExpectedResult() {
        XCTAssertEqual(subject.viewId, "test-user-1-spotlight")
    }

    // MARK: - Appearance

    func test_appearance() {
        AssertSnapshot(
            subject.frame(width: 375),
            size: .zero
        )
    }
}
