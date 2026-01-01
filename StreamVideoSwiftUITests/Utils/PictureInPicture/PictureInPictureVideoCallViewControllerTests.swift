//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVKit
import Combine
import StreamVideo
@testable import StreamVideoSwiftUI
import SwiftUI
import XCTest

@available(iOS 15.0, *)
@MainActor
final class PictureInPictureVideoCallViewControllerTests: XCTestCase, @unchecked Sendable {

    private lazy var store: PictureInPictureStore! = .init()
    private lazy var subject: PictureInPictureVideoCallViewController! = .init(store: store)
    private lazy var disposableBag: DisposableBag! = .init()
    
    override func tearDown() async throws {
        subject = nil
        store = nil
        disposableBag = nil
        try await super.tearDown()
    }

    // MARK: - View Lifecycle Tests
    
    func test_viewDidLoad_setsUpViewHierarchy() {
        // When
        subject.viewDidLoad()

        // Then
        XCTAssertEqual(subject.view.subviews.count, 1)
        XCTAssertEqual(subject.view.backgroundColor, .clear)

        let contentView = subject.view.subviews.first
        XCTAssertNotNil(contentView)
        XCTAssertFalse(contentView?.translatesAutoresizingMaskIntoConstraints ?? true)
    }
    
    func test_viewDidLayoutSubviews_updatesContentViewBounds() {
        // Given
        subject.viewDidLoad()
        let testBounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        subject.view.bounds = testBounds

        // When
        subject.viewDidLayoutSubviews()

        // Then
        let contentView = subject.view.subviews.first
        XCTAssertEqual(contentView?.bounds, testBounds)
    }
    
    func test_viewDidLayoutSubviews_updatesStoreContentSize() async {
        // Given
        subject.viewDidLoad()
        let testSize = CGSize(width: 100, height: 100)
        subject.view.bounds = CGRect(origin: .zero, size: testSize)

        // When
        subject.viewDidLayoutSubviews()

        // Then
        await fulfilmentInMainActor { self.store.state.contentSize == testSize }
    }
    
    // MARK: - Preferred Content Size Tests

    func test_preferredContentSizeUpdatedOnStore_nonZero_preferredContentSizeUpdated() async {
        let expected = CGSize(width: 1, height: 1)

        _ = subject
        store.dispatch(.setPreferredContentSize(expected))

        await fulfilmentInMainActor { self.subject.preferredContentSize == expected }
    }

    func test_preferredContentSizeUpdatedOnStore_zero_preferredContentSizeWasNotUpdated() async {
        let expected = CGSize(width: 1, height: 1)

        _ = subject
        store.dispatch(.setPreferredContentSize(expected))
        store.dispatch(.setPreferredContentSize(.zero))

        await fulfilmentInMainActor { self.subject.preferredContentSize == expected }
    }
}
