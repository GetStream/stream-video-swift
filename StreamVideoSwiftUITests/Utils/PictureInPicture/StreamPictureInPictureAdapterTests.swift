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

    func test_callUpdated_storeWasUpdated() async {
        let call = MockCall(.dummy())
        _ = subject
        await wait(for: 0.5)

        subject.call = call

        await fulfilmentInMainActor { self.subject.store?.state.call?.cId == call.cId }
    }

    // MARK: - SourceView updated

    func test_sourceViewUpdated_storeWasUpdated() async {
        let view = UIView()
        _ = subject
        await wait(for: 0.5)

        subject.sourceView = view

        await fulfilmentInMainActor { self.subject.store?.state.sourceView === view }
    }
}
