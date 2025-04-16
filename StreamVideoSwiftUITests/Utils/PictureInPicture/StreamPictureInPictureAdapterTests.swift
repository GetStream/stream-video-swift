//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
@available(iOS 15.0, *)
final class StreamPictureInPictureAdapterTests: XCTestCase, @unchecked Sendable {

    private lazy var subject: StreamPictureInPictureAdapter! = .init()

    // MARK: - Call updated

    func test_callUpdated_storeWasUpdated() {
        let call = MockCall(.dummy())

        subject.call = call

        XCTAssertEqual(subject.store.state.call?.cId, call.cId)
    }

    // MARK: - SourceView updated

    func test_sourceViewUpdated_storeWasUpdated() {
        let view = UIView()

        subject.sourceView = view

        XCTAssertTrue(subject.store.state.sourceView === view)
    }
}
