//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
@testable import StreamVideoSwiftUI
import SnapshotTesting
import XCTest
import Foundation

@MainActor
final class DominantSpeakerLayoutComponent_Tests: StreamVideoUITestCase {

    private lazy var subject: DominantSpeakerLayoutComponent! = DominantSpeakerLayoutComponent(
        viewFactory: TestViewFactory(),
        participant: .dummy(
            id: "test-user-1",
            name: "test-user-1",
            profileImageURL: .init(string: "https://picsum.photos/id/237/200/200")!
        ),
        viewIdSuffix: "spotlight",
        call: nil,
        availableFrame: .init(origin: .zero, size: .init(width: 200, height: 200)),
        onChangeTrackVisibility: { _,_ in}
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
